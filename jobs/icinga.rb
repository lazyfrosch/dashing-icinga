# from  https://github.com/roidelapluie/dashing-scripts/blob/master/jobs/icinga.rb
# with modifications and additions by Markus Frosch <markus.frosch@netways.de>
require "net/https"
require "uri"

def print_warning(msg)
  puts "\e[33m" + msg + "\e[0m"
end

SCHEDULER.every '15s', :first_in => 0 do |job|
  if ! defined? settings.icinga_cgi
    print_warning("Please configure icinga_cgi in config.ru!")
    next
  end

  icinga_user = nil
  if defined? settings.icinga_user
    icinga_user = settings.icinga_user
  end
  icinga_pass = nil
  if defined? settings.icinga_pass
    icinga_pass = settings.icinga_pass
  end

  # host
  result = get_status_host(settings.icinga_cgi, icinga_user, icinga_pass)
  totals = result["totals"]

  moreinfo = []
  color = 'green'
  display = totals["count"]
  legend = ''

  if totals["unhandled"] > 0
    display = totals["unhandled"].to_s
    legend = 'unhandled'
    if totals["down"] > 0 or totals["unreachable"] > 0
      color = 'red'
    end
  end

  moreinfo.push(totals["down"].to_s + " down") if totals["down"] > 0
  moreinfo.push(totals["unreachable"].to_s + " unreachable") if totals["unreachable"] > 0
  moreinfo.push(totals["ack"].to_s + " ack") if totals["ack"] > 0
  moreinfo.push(totals["downtime"].to_s + " in downtime") if totals["downtime"] > 0

  send_event('icinga-hosts', {
    value: display,
    moreinfo: moreinfo * " | ",
    color: color,
    legend: legend
  })

  send_event('icinga-hosts-latest', {
    rows: result["latest"],
    moreinfo: result["latest_moreinfo"]
  })

  # service
  result = get_status_service(settings.icinga_cgi, icinga_user, icinga_pass)
  totals = result["totals"]

  moreinfo = []
  color = 'green'
  display = totals["count"]
  legend = ''

  if totals["unhandled"] > 0
    display = totals["unhandled"].to_s
    legend = 'unhandled'
    if totals["critical"] > 0
      color = 'red'
    elsif totals["warning"] > 0
      color = 'yellow'
    elsif totals["unknown"] > 0
      color = 'orange'
    end
  end

  moreinfo.push(totals["critical"].to_s + " critical") if totals["critical"] > 0
  moreinfo.push(totals["warning"].to_s + " warning") if totals["warning"] > 0
  moreinfo.push(totals["ack"].to_s + " ack") if totals["ack"] > 0
  moreinfo.push(totals["downtime"].to_s + " in downtime") if totals["downtime"] > 0

  send_event('icinga-services', {
    value: display,
    moreinfo: moreinfo * " | ",
    color: color,
    legend: legend
  })

  send_event('icinga-services-latest', {
    rows: result["latest"],
    moreinfo: result["latest_moreinfo"]
  })

end

def request_status(url, user, pass, type)
  case type
  when "host"
    url_part = "style=hostdetail"
  when "service"
    url_part = "host=all&hoststatustypes=3"
  else
    throw "status type '" + type + "' is not supported!"
  end

  uri = URI.parse(url + "?" + url_part + "&nostatusheader&jsonoutput&sorttype=1&sortoption=6")

  http = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https')
  request = Net::HTTP::Get.new(uri.request_uri)
  if (user and pass)
    request.basic_auth(user, pass)
  end
  response = http.request(request)
  return JSON.parse(response.body)["status"][type+"_status"]
end

def get_status_service(url, user, pass)
  service_status = request_status(url, user, pass, 'service')

  latest = []
  latest_counter = 0
  totals = {
    "unhandled" => 0,
    "warning" => 0,
    "critical" => 0,
    "unknown" => 0,
    "ack" => 0,
    "downtime" => 0,
    "count" => 0
  }

  service_status.each { |status|
    totals['count'] += 1

    if status["in_scheduled_downtime"]
      totals['downtime'] += 1
      next
    elsif status["has_been_acknowledged"]
      totals['ack'] += 1
      next
    end

    problem = 0
    case status["status"]
    when "CRITICAL"
      totals['critical'] += 1
      totals['unhandled'] += 1
      problem = 1
    when "WARNING"
      totals['warning'] += 1
      totals['unhandled'] += 1
      problem = 1
    when "UNKNOWN"
      totals['unknown'] += 1
      totals['unhandled'] += 1
      problem = 1
    end

    if problem == 1
      latest_counter += 1
      if latest_counter <= 15
        latest.push({ cols: [
          { value: status['host_name'], class: 'icinga-hostname' },
          { value: status['status'], class: 'icinga-status icinga-status-'+status['status'].downcase },
        ]})
        latest.push({ cols: [
          { value: status['service_description'], class: 'icinga-servicename' },
          { value: status['duration'].gsub(/^0d\s+(0h\s+)?/, ''), class: 'icinga-duration' }
        ]})
      end
    end
  }

  latest_moreinfo = latest_counter.to_s + " problems"
  if latest_counter > 15
    latest_moreinfo += " | " + (latest_counter - 15).to_s + " not listed"
  end

  return {
    "totals" => totals,
    "latest" => latest,
    "latest_moreinfo" => latest_moreinfo
  }
end

def get_status_host(url, user, pass)
  host_status = request_status(url, user, pass, 'host')

  latest = []
  latest_counter = 0
  totals = {
    "unhandled" => 0,
    "unreachable" => 0,
    "down" => 0,
    "ack" => 0,
    "downtime" => 0,
    "count" => 0
  }

  host_status.each { |status|
    totals['count'] += 1

    if status["in_scheduled_downtime"]
      totals['downtime'] += 1
      next
    elsif status["has_been_acknowledged"]
      totals['ack'] += 1
      next
    end

    problem = 0
    case status["status"]
    when "DOWN"
      totals['down'] += 1
      totals['unhandled'] += 1
      problem = 1
    when "UNREACHABLE"
      totals['unreachable'] += 1
      totals['unhandled'] += 1
      problem = 1
    end

    if problem == 1
      latest_counter += 1
      if latest_counter <= 15
        latest.push({ cols: [
          { value: status['host_name'], class: 'icinga-hostname' },
          { value: status['status'], class: 'icinga-status icinga-status-'+status['status'].downcase },
        ]})
        latest.push({ cols: [
          { value: status['duration'].gsub(/^0d\s+(0h\s+)?/, ''), class: 'icinga-duration', colspan: 2 },
        ]})
      end
    end
  }

  latest_moreinfo = latest_counter.to_s + " problems"
  if latest_counter > 15
    latest_moreinfo += " | " + (latest_counter - 15).to_s + " not listed"
  end

  return {
    "totals" => totals,
    "latest" => latest,
    "latest_moreinfo" => latest_moreinfo
  }
end

