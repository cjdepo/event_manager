require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'


def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
    if phone_number.to_s.length == 10
        phone_number.to_s
    elsif phone_number.to_s.length == 11 && phone_number.to_s[0] == "1"
        phone_number.to_s[1..10]
    else
        "N/A"
    end
end


def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        legislators = civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
        
    rescue
        'You can find your representative by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

puts 'EventManager initialized.'

contents = CSV.open(
    'event_attendees.csv',
    headers: true, 
    header_converters: :symbol,
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours = []
weekdays = []
contents.each_with_index do |row, i|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    regdate = row[:regdate]
    date = Time.strptime(regdate, "%m/%d/%y %k:%M")
    weekdays[i] = date.wday
    hours[i] = date.hour
    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)
end

hour_count = {}
hours.uniq.each{ |hour| hour_count[hour.to_s] = hours.count(hour) }
hour_count_sorted = hour_count.sort_by{ |k, v| -v }.to_h
puts "Most popular registration hours:"
puts hour_count_sorted

weekday_count = {}
weekdays.uniq.each{ |weekday| weekday_count[weekday.to_s] = weekdays.count(weekday) }
weekday_count_sorted = weekday_count.sort_by{ |k, v| -v }.to_h
puts "Most popular registration weekdays:"
puts weekday_count_sorted

