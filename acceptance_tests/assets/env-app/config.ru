require 'json'

app = lambda do |env|
  body = "#{ENV.to_hash.to_json}"

  [ 200,
    { "Content-Type" => "text/plain",
      "Content-Length" => body.length.to_s
    },
    [body]
  ]
end

run app
