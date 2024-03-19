require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]

end

def legilators_by_zip_code(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"]
      ).officials

  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'

    end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone(phone)
  phone = phone.gsub(/[- .()]/, '')
  if phone.length == 10
    phone
  elsif phone.length == 11 && phone[0] == "1"
    phone = phone[1..10]
  else
    "bad number!"
  end
end

def most_common(array)
  array.max_by {|a| array.count(a)}
end

weekdays = {
  0 => "Sunday",
  1 => "Monday",
  2 => "Tuesday",
  3 => "Wednesday",
  4 => "Thursday",
  5 => "Friday",
  6 => "Saturday"
}

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
  )
  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter
  days = []
  hours = []


contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone(row[:homephone])


  raw_date = row[:regdate]
  datedate = Time.strptime(raw_date, "%m/%d/%y %H:%M")
  days << datedate.wday
  hours << datedate.hour




  legislators = legilators_by_zip_code(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)



  # puts "#{name} - #{zipcode} - #{legislators}"

end

p "The most common day is #{weekdays[most_common(days)]}"
p "The most common hour is #{most_common(hours)}"
