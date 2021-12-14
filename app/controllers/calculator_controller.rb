require 'csv'
require 'net/http'
require 'json'

class CalculatorController < ApplicationController
  def index
  end

  def new
  end

  def create
    # get base information
    file = params[:file] # fetches the csv
    file_name = "#{file.original_filename.split('.').first}+ #{Time.now.to_s}".gsub(/[^0-9A-Za-z]/, '') # defines the time, in case calculations gets killed
    # here starts the calculation execution
    input = extract_csv(file)

    # calculate and receive CO2 amounts
    get_co2_amounts_and_save_to_db(input, file_name)

    # save to csv
    save_to_csv(file_name)

    # download
    @csv_file = (file_name + "_results.csv")

    send_file(@csv_file)
    # format.csv { send_data csv_file, filename: fn }
  end

  #def send_csv(csv_file)
  #  send_data csv_file, :type => 'text/csv; charset=utf-8; header=present', :disposition => 'attachment; filename=payments.csv'
  #end

  def download
    raise
  end


  def extract_csv(file) # extracts and formats the content of the csv
    input_array = []
    CSV.foreach(file, headers: true) do |row|
      values = row.to_s.split(';')

      data_hash = { customer_id: values[0],
                    calculation_type: values[1],
                    origin:values[2],
                    destination: values[3],
                    weight_in_tonnes: values[4],
                    specific_method: values[5],
                    fuel_type: values[6],
                    car_type: values[7],
                    plane_type: values[8],
                    freight_type: values[9]} # don't forget to add migration and to also add in "calculate_generically"
      input_array << data_hash
    end
    input_array
  end

  def get_co2_amounts_and_save_to_db(input_array, file_name)
    output_array = []
    input_array.each do |record|
      co2 = calculate_generically(record) # returns the co2 value of "any" calculation
      newrecord = CarbonRecord.new(
        customer_id: record[:customer_id],
        calculation_type: record[:calculation_type],
        origin: record[:origin],
        destination: record[:destination],
        weight_in_tonnes: record[:weight_in_tonnes],
        specific_method: record[:specific_method],
        fuel_type: record[:fuel_type],
        car_type: record[:car_type],
        plane_type: record[:plane_type],
        freight_type: record[:freight_type],
        co2_in_g: co2,
        file_name: file_name
      )
      newrecord.save
      puts newrecord
    end
  end


  # defines the base parameters for calling the API
  def base_parameters
    uri = URI('https://api.squake.cloud/carbon_activities')
    headers = { 'Content-Type': 'application/json', 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJjbGllbnRfa2V5IjoiYzY2ZTc5NmEtZmY1OC00ZmZhLTk5MGYtNDYyYzg4OGZhZTQxIiwiZXhwIjoxNjQ2OTIwNjkzfQ.WAluE4fAyLotjJfoi6j5FlTUCnWY20eobJb3hrZx4_Q' }
    request = Net::HTTP::Post.new(uri, headers)
    [uri, request]
  end

  # fetches the results from the API
  def get_api_result(uri, request)
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  # extracts grams from API result
  def get_grams(result)
    res = JSON.parse(result.body)
    res.dig("items_results", 0, "co2_in_grams")
  end

  def calculate_generically(record)
    uri = base_parameters[0]
    request = base_parameters[1]
    request.body = {
      items: [
        {
          carbon_activity_type: record[:calculation_type],
          parameters: {
            origin: record[:origin],
            destination: record[:destination],
            weight_in_tonnes: record[:weight_in_tonnes].to_f,
            plane_type: record[:specific_method],
            fuel_type: record[:fuel_type],
            car_type: record[:car_type],
            plane_type: record[:plane_type],
            freight_type: record[:freight_type]
          }
        }
      ]
    }.to_json
    res = get_api_result(uri, request)
    get_grams(res)
  end

  def save_to_csv(file_name)
  CSV.open(file_name + "_results.csv", 'wb') do |csv|
    # this creates the header with all column names
    csv << CarbonRecord.column_names
    # this goes through each record, creates an array & saves it to the csv
    CarbonRecord.where(file_name: file_name).each do |record|
      array = []
      CarbonRecord.column_names.each do |column|
        array << record[column]
      end
      csv << array
    end
    csv
  end
end

end
