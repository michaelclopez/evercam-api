require_relative "./web_router"

module Evercam
  class WebRootRouter < WebRouter
    get '/' do
      headers 'Access-Control-Allow-Origin' => '*'
      "It works!"
    end
  end
end
