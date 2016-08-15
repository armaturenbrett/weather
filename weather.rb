$widget_scheduler.every '15m', first_in: '5s' do
  require 'action_view'
  include ActionView::Helpers::NumberHelper

  url = "http://api.openweathermap.org/data/2.5/forecast" \
        "?q=#{$config['weather']['location']}" \
        "&appid=#{$config['weather']['api_key']}"

  response = JSON.parse(Net::HTTP.get(URI(url)))

  data = {
    weather: {
      current: {},
      history: {
        temperatures: [],
        rain: []
      }
    },
    labels: {
      x: [],
      y: {
        temperature: []
      }
    }
  }

  temperatures = response['list'].map { |i| i['main']['temp'] - 273.15 }[0..8]

  response['list'][0..8].each_with_index do |data_point, i|
    temperature = data_point['main']['temp'] - 273.15
    rain = data_point['rain']['3h'] rescue 0.0
    data[:weather][:current] = {
      temperature: number_with_precision(temperature, precision: 1).tr('.', ','),
      rain: number_with_precision(rain, precision: 1).tr('.', ',')
    } if i.zero?

    temperature_value = 100 - ((100.0 / (temperatures.max - temperatures.min)) * (temperature - temperatures.min))

    data[:weather][:history][:temperatures] << { x: i, y: temperature_value.round(0) }
    data[:weather][:history][:rain] << rain

    data[:labels][:x] << {
      label: Time.at(data_point['dt']).to_datetime.strftime('%H:%M'),
      position: (i * (100.0 / 8)).round(2)
    }
  end

  (temperatures.min.round(0)..temperatures.max.round(0)).each_with_index do |temperature, i|
    data[:labels][:y][:temperature] << {
      label: "#{temperature} °C",
      position: (i * (100.0 / (temperatures.max - temperatures.min + 1))).round(2)
    }
  end

  WidgetDatum.new(name: 'weather', data: data).save
end
