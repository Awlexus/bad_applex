# BadApplex

## Additional requirements
  * ffmpeg
  * Rust programming language
  * youtube-dl **(optional, to download the reference video)**

## Installation

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Download reference video from [Youtube](https://www.youtube.com/watch?v=UkgK8eUdpAo) and save it under `priv/static/videos/bad_apple.mkv`
  ```bash
  $ youtube-dl https://www.youtube.com/watch\?v\=UkgK8eUdpAo -o priv/static/videos/bad_apple.mkv
  ```
  * Compile application with `mix compile`
  * Extract image data from the video with the provided mix task `mix extract_pixels`
  ```bash
  $ mix extract_pixels priv/static/videos/bad_apple.mkv priv/image_data
  ```
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix


