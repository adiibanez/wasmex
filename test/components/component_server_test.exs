defmodule Wasmex.Components.GenServerTest do
  use ExUnit.Case, async: true
  alias Wasmex.Wasi.WasiP2Options

  test "interacting with a component GenServer" do
    component_bytes = File.read!("test/component_fixtures/component_types/component_types.wasm")
    component_pid = start_supervised!({Wasmex.Components, bytes: component_bytes})
    assert {:ok, "mom"} = Wasmex.Components.call_function(component_pid, "id-string", ["mom"])
    assert {:error, _error} = Wasmex.Components.call_function(component_pid, "garbage", ["wut"])
  end

  test "loading a component from a path" do
    component_pid =
      start_supervised!(
        {Wasmex.Components, path: "test/component_fixtures/component_types/component_types.wasm"}
      )

    assert {:ok, "mom"} = Wasmex.Components.call_function(component_pid, "id-string", ["mom"])
  end

  test "specifying options as a map" do
    component_pid =
      start_supervised!(
        {Wasmex.Components,
         %{path: "test/component_fixtures/component_types/component_types.wasm"}}
      )

    assert {:ok, "mom"} = Wasmex.Components.call_function(component_pid, "id-string", ["mom"])
  end

  test "unrecoverable errors crash the process" do
    component_bytes = File.read!("test/component_fixtures/component_types/component_types.wasm")
    component_pid = start_supervised!({Wasmex.Components, bytes: component_bytes})

    assert catch_exit(
             Wasmex.Components.call_function(component_pid, "id-record", [%{not: "expected"}])
           )
  end

  test "using the component server macro" do
    component_bytes = File.read!("test/component_fixtures/hello_world/hello_world.wasm")

    component_pid =
      start_supervised!(
        {HelloWorld, bytes: component_bytes, wasi: %WasiP2Options{allow_http: true}}
      )

    assert {:ok, "Hello, Elixir from a function defined in the module!"} =
             HelloWorld.greet(component_pid, "Elixir")

    assert {:ok, [greeting1, greeting2]} =
             HelloWorld.multi_greet(component_pid, "Elixir", 2)

    assert greeting1 =~ "Hello"
    assert greeting2 =~ "Hello"
  end

  test "register by name" do
    component_bytes = File.read!("test/component_fixtures/component_types/component_types.wasm")

    {:ok, _pid} =
      start_supervised({Wasmex.Components, bytes: component_bytes, name: ComponentTypes})

    assert {:ok, "mom"} = Wasmex.Components.call_function(ComponentTypes, "id-string", ["mom"])
  end
end
