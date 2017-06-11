# Temp

Creating temporary files and directories.

The files and directories will be deleted, when the process dies.

## Installation

The package can be installed by
adding `temp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:temp, "~> 0.1", git: "https://github.com/IanLuites/elixir-temp.git"}]
end
```

## Use
```elixir
iex> Temp.file
{:ok, "tmp/AAVRr-E6RrU3NzM1N4EBS-x09ag1E57J"}

iex> Temp.file!
"tmp/AAVRr-FxLb43NzM1N-WbrTTTHCpJfuBD"

iex> Temp.file! suffix: ".html"
"tmp/AAVRsAT5AGY3OTQzOTWeb-v3R4Db1kn_.html"

iex> Temp.file! prefix: "2017-"
"tmp/2017-AAVRsAXi3TI3OTQzOT5Pjwlxh7Gs-lKz"
```
