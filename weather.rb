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
        temperature: [],
        rain: []
      }
    }
  }

  temperatures = response['list'].map { |i| i['main']['temp'] - 273.15 }[0..8]
  rains = []
  response['list'].each_with_index do |value, i|
    rain = value['rain']['3h'].to_f rescue 0.0
    rains << rain
  end

  response['list'][0..8].each_with_index do |data_point, i|
    temperature = data_point['main']['temp'] - 273.15
    rain = data_point['rain']['3h'].to_f rescue 0.0
    data[:weather][:current] = {
      temperature: number_with_precision(temperature, precision: 1).tr('.', ','),
      rain: number_with_precision(rain, precision: 1).tr('.', ',')
    } if i.zero?

    temperature_value = (100.0 / (temperatures.max - temperatures.min)) * (temperature - temperatures.min)
    rain_value = (100.0 / (rains.max - rains.min)) * (rain - rains.min)

    data[:weather][:history][:temperatures] << { x: i, y: (100 - temperature_value) }
    data[:weather][:history][:rain] << { x: i + 0.05, y: (100 - rain_value), height: rain_value }

    data[:labels][:x] << {
      label: Time.at(data_point['dt']).to_datetime.strftime('%H:%M'),
      position: (i * (100.0 / 8)).round(2)
    }
  end

  (temperatures.min.round(0)..temperatures.max.round(0)).each_with_index do |temperature, i|
    data[:labels][:y][:temperature] << {
      label: "#{temperature} °C",
      position: (i * (100.0 / (temperatures.max - temperatures.min))).round(2)
    }
  end

  rain_label_scale = 1.0

  ((rains.min * rain_label_scale).round(0)..(rains.max * rain_label_scale).round(0)).each_with_index do |rain, i|
    data[:labels][:y][:rain] << {
      label: "#{(rain / rain_label_scale).round(1).to_s.tr('.', ',')} mm",
      position: (i * (100.0 / (rain_label_scale * (rains.max - rains.min)))).round(2)
    }
  end

  WidgetDatum.new(name: 'weather', data: data).save
end
