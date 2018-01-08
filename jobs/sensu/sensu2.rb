#!/usr/bin/env ruby

require 'json'
require 'open-uri'

SENSU_API_ENDPOINT2 = 'http://sensu.mycompany.com/'

SYSTEMS = [ 'jenkins', 'logstash-test', 'logstash-production', 'git', 'nexus']

class Sensu2
  def self.status(crit, warn)
    return "red" if crit > 0
    return "yellow" if warn > 0
    return "green"
  end
end

SCHEDULER.every '15s', :first_in => 0 do |job|
  ENV['http_proxy'] = nil
  critical_count = 0
  warning_count = 0
  #unknown_count = 0

  client_warning = Array.new
  client_critical = Array.new
  #client_unknown = Array.new


  warn = Array.new
  crit = Array.new
  stashed = Array.new

  systems = Hash.new
  SYSTEMS.each { | sys | systems[sys] = [0, 0] }


  response1 = open(SENSU_API_ENDPOINT2+"/events").read
  events = JSON.parse(response1)

  response2 = open(SENSU_API_ENDPOINT2+"/stashes").read
  stashes = JSON.parse(response2)

  events.each do |event|
    check = event['check']
    status = check['status']
    name = check['name']
    system = check['custom_values']['system'] if check['custom_values']
    hostname = event['client']['name']
    stashName = "silence/#{hostname}/#{name}"
    isStashed = false

    stashes.each do |stash|
      if stash['path'] == stashName
        isStashed = true
      end
    end

    #for those not stashed, we do care its status
    if (!isStashed)
      if status == 1
        warn.push(event)
        warning_count += 1
      elsif status == 2
        crit.push(event)
        critical_count += 1
      end

      if system != nil and systems.key?(system)
        systems[system] = [systems[system][0], systems[system][1].to_i + 1] if status == 1
        systems[system] = [systems[system][0].to_i + 1, systems[system][1]] if status == 2
      end

      if system =~ /logstash|redis|elasticsearch/
        if check['custom_values']['environment'] == 'production_logstash'
          system = "logstash-prod"
          systems[system] = [systems[system][0], systems[system][1].to_i + 1] if status == 1
          systems[system] = [systems[system][0].to_i + 1, systems[system][1]] if status == 2
        else
          system = "logstash-test"
          systems[system] = [systems[system][0], systems[system][1].to_i + 1] if status == 1
          systems[system] = [systems[system][0].to_i + 1, systems[system][1]] if status == 2
        end
      end

    else
       stashed.push(event)
    end
  end

  warn.each do |entry|
    client_warning.push( {:label=>entry['client']['name'].split('.')[0], :value=>entry['check']['name']} )
  end
  send_event('sensu-warn-list-new', { items: client_warning })


  crit.each do |entry|
    client_critical.push( {:label=>entry['client']['name'].split('.')[0], :value=>entry['check']['name']} )
  end
  send_event('sensu-crit-list-new', { items: client_critical })

  systems.each do |system, event_counts|
    if event_counts[0] > 0
      send_event("sensu-status-#{system}", {criticals: event_counts[0], warnings: 0, status: Sensu2.status(event_counts[0], 0) })
    else
      send_event("sensu-status-#{system}", {criticals: 0, warnings: event_counts[1], status: Sensu2.status(0, event_counts[1]) })
    end
  end


end
