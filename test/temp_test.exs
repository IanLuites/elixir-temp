defmodule TempTest do
  use ExUnit.Case

  describe "file" do
    test "can be created" do
      assert File.exists?(Temp.file!)
    end

    test "gets cleaned up after process dead" do
      test_pid = self()

      pid =
        spawn fn ->
          file = Temp.file!

          assert File.exists?(file)

          send test_pid, {:filename, file}
        end

      file =
        receive do
          {:filename, file} -> file
        end

      # Give time for file cleanup
      :timer.sleep(100)
      refute Process.alive?(pid)
      refute File.exists?(file)
    end

    test "gets cleaned after application shutdown" do
      file = Temp.file!

      assert File.exists?(file)

      # Simulate Application shutdown
      Temp.Cleanup
      |> Process.whereis
      |> Process.exit(:normal)

      # Give time for file cleanup
      :timer.sleep(100)
      refute File.exists?(file)
    end

    test "keeps trying to generate files if file already exist (But hits a limit)" do
      :meck.new File, [:passthrough]
      :meck.expect File, :exists?, fn _ -> true end

      on_exit &:meck.unload/0

      assert Temp.file == {:error, :unique_generation_limit}
    end

    test "can have a prefix" do
      file = Temp.file! prefix: "prefix-"

      assert File.exists?(file)
      assert String.starts_with?(Path.basename(file), "prefix-")
    end

    test "can have a suffix" do
      file = Temp.file! suffix: "suffix.txt"

      assert File.exists?(file)
      assert String.ends_with?(Path.basename(file), "suffix.txt")
    end
  end

  describe "file!" do
    test "raises RuntimeError on error" do
      :meck.new File, [:passthrough]
      :meck.expect File, :mkdir_p, fn _ -> {:error, :mocked} end

      on_exit &:meck.unload/0

      assert_raise RuntimeError, fn -> Temp.file! end
    end

    test "raises RuntimeError on error (for touch)" do
      :meck.new File, [:passthrough]
      :meck.expect File, :touch, fn _ -> {:error, :mocked} end

      on_exit &:meck.unload/0

      assert_raise RuntimeError, fn -> Temp.file! end
    end
  end

  describe "cleanup" do
    test "manually deletes files" do
      file = Temp.file!

      assert File.exists?(file)

      Temp.cleanup

      refute File.exists?(file)
    end

    test "manually deletes files with labels" do
      file_labeled = Temp.file! label: :delete

      assert File.exists?(file_labeled)

      Temp.cleanup :delete

      refute File.exists?(file_labeled)
    end

    test "manually deletes selected files with labels" do
      file = Temp.file!
      file_labeled = Temp.file! label: :delete

      assert File.exists?(file)
      assert File.exists?(file_labeled)

      Temp.cleanup :delete

      assert File.exists?(file)
      refute File.exists?(file_labeled)
    end

    test "manually can be called without creating files" do
      assert Temp.cleanup == :ok
      assert Temp.cleanup(:invalid_label) == :ok
    end
  end
end
