defmodule Mix.Tasks.ExtractPixels do
  @shortdoc "Extract the image data to be used for displaying"
  @moduledoc """
  Extracts the raw pixels used for the liveview. FFMPEG is required for extracting the images

  Usage:
  mix extract_pixels input_file output_file [--filters filters]

  * --filters - Options that will be directly passed to ffmpeg's video filter option (-vf)
                Default: "scale=48:-1"

                The default set here is a good balance between performance, fluidity and sharpness.
                Going higher than this to for example "72:-1" Causes a noticable delay between frames,
                so I do not recommend it, at least not without lowering the framerate.

                Going even higher than that will cause the beam to run out of memory while starting or
                while parsing the video data.
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {input_file, output_file, opts} = validate_input!(args)
    ffmpeg = find_executable!("ffmpeg")
    ffprobe = find_executable!("ffprobe")
    duration = extract_duration!(ffprobe, input_file)
    image_data = extract_frames!(ffmpeg, input_file, opts)

    data =
      image_data
      |> Map.put(:duration, duration)
      |> :erlang.term_to_binary()

    File.write!(output_file, data)
    Mix.shell().info("Output written to \"#{output_file}\"")
  end

  defp extract_duration!(ffprobe, input_file) do
    args = [input_file, "-of", "json", "-show_streams"]

    case System.cmd(ffprobe, args) do
      {output, 0} -> parse_duration(output)
      {reason, status} -> error("ffprobe exited with status #{status}: #{reason}")
    end
  end

  defp extract_frames!(ffmpeg, input_file, opts) do
    case System.cmd(ffmpeg, ffmpeg_options(input_file, opts)) do
      {output, 0} -> parse_output(output)
      {error, status} -> error("ffmpeg exited with status #{status}:\n#{error}")
    end
  end

  defp validate_input!([input_file, output_file | args]) do
    unless File.exists?(input_file), do: error("Input file does not exist")

    {opts, _} = OptionParser.parse!(args, strict: [filters: :string])

    {input_file, output_file, opts}
  end

  defp validate_input!(_args) do
    error("input_file and output_file are required")
  end

  defp ffmpeg_options(input_file, opts) do
    filters = Keyword.get(opts, :filters, "scale=48:-1")

    ["-i", input_file, "-vf", filters, "-c:v", "pbm", "-f", "image2pipe", "-"]
  end

  defp parse_output("P4\n" <> rest = binary) do
    {width, " " <> rest} = Integer.parse(rest)
    {height, _} = Integer.parse(rest)
    [{a, b}] = Regex.run(~r/\d+ \d+\n/, binary, return: :index)
    header_size = a + b
    chunk_size = ceil(width / 8) * height
    output = parse_output(binary, width, height, header_size, chunk_size, [])
    %{frame_count: Enum.count(output), height: height, width: width, frames: output}
  end

  defp parse_output("", _, _, _, _, acc), do: Enum.reverse(acc)

  defp parse_output(binary, width, height, header_size, chunk_size, acc) do
    <<_header::binary-size(header_size), chunk::big-binary-size(chunk_size), rest::binary>> =
      binary

    pixels = extract_pixels(chunk, width, height)
    parse_output(rest, width, height, header_size, chunk_size, [pixels | acc])
  end

  defp parse_duration(output) do
    duration_str =
      output
      |> Jason.decode!()
      |> Map.fetch!("streams")
      |> hd()
      |> Map.fetch!("tags")
      |> Map.fetch!("DURATION")

    ~r/(?<hours>\d+):(?<minutes>\d+):(?<seconds>\d+)\.?(?<milliseconds>\d{3})?/
    |> Regex.named_captures(duration_str)
    |> Enum.reduce(0, fn
      {"hours", hours}, acc ->
        acc + String.to_integer(hours) * 60 * 60 * 1000

      {"minutes", minutes}, acc ->
        acc + String.to_integer(minutes) * 60 * 1000

      {"seconds", seconds}, acc ->
        acc + String.to_integer(seconds) * 1000

      {"milliseconds", milliseconds}, acc ->
        acc + String.to_integer(milliseconds)
    end)
  end

  defp find_executable!(executable) do
    if executable = System.find_executable(executable) do
      executable
    else
      error("#{executable} not found")
    end
  end

  defp error(reason) do
    Mix.shell().error(reason)
    System.halt(-1)
  end

  use Rustler,
    otp_app: :bad_applex,
    crate: :pbm_converter

  # I have given up writing this in elixir
  # http://fejlesztek.hu/pbm-p4-image-file-format/
  def extract_pixels(_bytes, _width, _heigth), do: :erlang.nif_error(:nif_not_loaded)
end
