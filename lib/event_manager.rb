require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0,5]
end

def legislators_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        legislators = civic_info.representative_info_by_address(
            address: zipcode,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

def clean_phone_number(phone_number)
    phone_number.to_s.gsub!(/[\D]/, '')
    if phone_number.length == 10
        phone_number
    elsif phone_number.length == 11 && phone_number[0] == "1"
        phone_number[1..10]
    else
        "Invalid Number"
    end
end

def add_count_hour(time, dictionary)
    hour = Time.strptime(time, "%m/%d/%y %k:%M").hour
    dictionary[hour.to_s.to_sym] += 1
end

def add_weekday_count(time, dictionary)
    weekday = Time.strptime(time, "%m/%d/%y %k:%M").wday
    dictionary[weekday.to_s.to_sym] += 1
end

puts 'Event Manager Initialized!'

contents = CSV.open(
    'event_attendees.csv', 
    headers: true,
    header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours_count = Hash.new(0)
weekday_count = Hash.new(0)

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)
    phone_number = clean_phone_number(row[:homephone])

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)

    add_count_hour(row[:regdate], hours_count)
    add_weekday_count(row[:regdate], weekday_count)

end

p "Max hour: #{hours_count.max_by {|k,v| v}}"
p "Max day: #{weekday_count.max_by {|k,v| v}}"