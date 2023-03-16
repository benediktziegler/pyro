defmodule Phlegethon.Components.Core do
  use Phlegethon.Component

  import Phlegethon.Gettext

  @moduledoc """
  Drop-in (prop/API compatible) replacement (and enhancement) of `core_components.ex` as generated by `Phoenix`, providing core UI components.

  Compared to the generated components, Phlegethon's implementation adds:

  - Maintenance/bugfixes/new features, since it's a library
  - A powerful [override system](#module-overridable-component-attributes) for customization
  - A special `:tails_classes` type that merges [Tailwind CSS](https://tailwindcss.com) classes via `Tails`
  - The button component implements both button and anchor tags (button-styled links!)
  - Inputs: `autofocus` prop to enable a hook for reliable focus on mount
  - A rich flash experience
    - Auto-remove after (configurable) timeout
    - Progress bar for auto-removed flash messages
    - Define which flashes are included in which trays (supports multiple trays)
  - Slightly cleaner, more semantic markup

  But wait, *there's more*! Those are just the `core_components` drop-in replacements  — Phlegethon has lots of other components on top of that. Check out the components section of the docs for the other modules.
  """

  @doc """
  TODO: This component is not fully converted to use overrides/properly styled.
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        Are you sure?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>

  JS commands may be passed to the `:on_cancel` and `on_confirm` attributes
  for the caller to react to each button press, for example:

      <.modal id="confirm" on_confirm={JS.push("delete")} on_cancel={JS.navigate(~p"/posts")}>
        Are you sure you?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}
  attr :show_js, :any, overridable: true, required: true
  attr :hide_js, :any, overridable: true, required: true
  attr :class, :tails_classes, overridable: true, required: true
  slot :inner_block, required: true
  slot :title
  slot :subtitle
  slot :confirm
  slot :cancel

  def modal(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <div
      id={@id}
      phx-mounted={@show && apply(@show_js, [%JS{}, @id])}
      phx-remove={apply(@hide_js, [%JS{}, @id])}
      class={@class}
    >
      <div id={"#{@id}-bg"} class="fixed inset-0 bg-zinc-50/90 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && apply(@show_js, [%JS{}, @id])}
              phx-window-keydown={apply(@hide_js, [@on_cancel, @id])}
              phx-key="escape"
              phx-click-away={apply(@hide_js, [@on_cancel, @id])}
              class="hidden relative rounded-2xl bg-white p-14 shadow-lg shadow-zinc-700/10 ring-1 ring-zinc-700/10 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={apply(@hide_js, [@on_cancel, @id])}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5 stroke-current" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <header :if={@title != []}>
                  <h1 id={"#{@id}-title"} class={@header_title_class}>
                    <%= render_slot(@title) %>
                  </h1>
                  <p
                    :if={@subtitle != []}
                    id={"#{@id}-description"}
                    class="mt-2 text-sm leading-6 text-zinc-600"
                  >
                    <%= render_slot(@subtitle) %>
                  </p>
                </header>
                <%= render_slot(@inner_block) %>
                <div :if={@confirm != [] or @cancel != []} class="ml-6 mb-4 flex items-center gap-5">
                  <.button
                    :for={confirm <- @confirm}
                    overrides={@overrides}
                    id={"#{@id}-confirm"}
                    phx-click={@on_confirm}
                    phx-disable-with
                    class="py-2 px-3"
                  >
                    <%= render_slot(confirm) %>
                  </.button>
                  <.link
                    :for={cancel <- @cancel}
                    phx-click={apply(@hide_js, [@on_cancel, @id])}
                    class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                  >
                    <%= render_slot(cancel) %>
                  </.link>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :flash, :map, default: %{}, doc: "The map of flash messages to display."

  attr :autoshow, :boolean,
    overridable: true,
    required: true,
    doc: "Whether to auto show the flash on mount"

  attr :close, :boolean, overridable: true, required: true, doc: "Whether the flash can be closed"
  attr :close_icon_name, :string, overridable: true, required: true
  attr :icon_name, :string, overridable: true, required: true
  attr :hide_js, :any, overridable: true, required: true
  attr :show_js, :any, overridable: true, required: true
  attr :title, :string, overridable: true
  attr :ttl, :integer, overridable: true, required: true
  attr :kind, :string, overridable: true, required: true, doc: "Used for styling and flash lookup"

  attr :style_for_kind, :string,
    overridable: true,
    doc: "Used for styling a flash with a different kind"

  attr :class, :tails_classes, overridable: true, required: true
  attr :control_class, :tails_classes, overridable: true
  attr :close_button_class, :tails_classes, overridable: true
  attr :close_icon_class, :tails_classes, overridable: true
  attr :message_class, :tails_classes, overridable: true, required: true
  attr :progress_class, :tails_classes, overridable: true, required: true
  attr :title_class, :tails_classes, overridable: true, required: true
  attr :title_icon_class, :tails_classes, overridable: true
  attr :rest, :global, doc: "The arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "The optional inner block to render the flash message"

  def flash(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={"phx-flash-#{@kind}"}
      phx-hook="PhlegethonFlashComponent"
      phx-click={
        @close &&
          apply(@hide_js, [JS.push("lv:clear-flash", value: %{key: @kind}), "#phx-flash-#{@kind}"])
      }
      data-show-exec-js={apply(@show_js, [%JS{}, "#phx-flash-#{@kind}"])}
      data-autoshow={@autoshow}
      data-ttl={@ttl}
      data-hide-exec-js={
        apply(@hide_js, [JS.push("lv:clear-flash", value: %{key: @kind}), "#phx-flash-#{@kind}"])
      }
      role="alert"
      class={@class}
      {@rest}
    >
      <section :if={@ttl > 0 || @close} class={@control_class}>
        <Phlegethon.Components.Extra.progress
          :if={@ttl > 0}
          overrides={@overrides}
          value={@ttl}
          max={@ttl}
          color={@kind}
          class={@progress_class}
          size="xs"
        />
        <div :if={@ttl <= 0} />
        <button :if={@close} type="button" class={@close_button_class} aria-label={gettext("close")}>
          <.icon overrides={@overrides} name={@close_icon_name} class={@close_icon_class} />
        </button>
      </section>
      <p :if={@title} class={@title_class}>
        <.icon :if={@icon_name} overrides={@overrides} name={@icon_name} class={@title_icon_class} />
        <%= @title %>
      </p>
      <p id={"phx-flash-#{@kind}-message"} class={@message_class}><%= msg %></p>
    </div>
    """
  end

  @doc """
  Shows the flash group with titles and content.

  ## Examples
      <.flash_group flash={@flash} />
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :flash, :map, required: true, doc: "The map of flash messages to display"

  attr :include_kinds, :list,
    overridable: true,
    required: true,
    doc: "The kinds of flashes to display"

  attr :class, :tails_classes, overridable: true, required: true
  attr :rest, :global, doc: "The arbitrary HTML attributes to add to the flash tray"

  def flash_group(assigns) do
    assigns = assign_overridables(assigns)
    assigns = assign(assigns, :flash, filter_flash(assigns[:flash], assigns[:include_kinds]))

    ~H"""
    <div :if={any_flash?(@flash)} overrides={@overrides} class={@class}>
      <.flash :for={{kind, _message} <- @flash} overrides={@overrides} {parse_flash(@flash, kind)} />
    </div>
    """
  end

  # defp filter_flash(nil, _kinds), do: %{}
  defp filter_flash(_flash, nil), do: %{}

  defp filter_flash(flash, kinds) do
    flash
    |> Enum.filter(fn {kind, _msg} ->
      kind in kinds
    end)
    |> Map.new()
  end

  defp any_flash?(flash), do: !Enum.empty?(Map.keys(flash))

  defp parse_flash(flash, kind) do
    flash
    |> Phoenix.Flash.get(kind)
    |> Jason.decode()
    |> case do
      {:ok, %{"message" => message} = parsed} ->
        Enum.reduce(parsed, [flash: Map.put(%{}, kind, message), kind: kind], fn
          {"message", _}, acc ->
            acc

          {_key, nil}, acc ->
            acc

          {"icon_name", value}, acc ->
            Keyword.put(acc, :icon_name, value)

          {"ttl", value}, acc ->
            Keyword.put(acc, :ttl, value)

          {"title", value}, acc ->
            Keyword.put(acc, :title, value)

          {"close", value}, acc ->
            Keyword.put(acc, :close, value)

          {"style_for_kind", value}, acc ->
            Keyword.put(acc, :style_for_kind, value)
        end)

      _ ->
        [flash: Map.put(%{}, kind, Map.get(flash, kind)), kind: kind]
    end
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :as, :any, default: nil, doc: "The server side parameter to collect all input under"
  attr :for, :any, required: true, doc: "The datastructure for the form"

  attr :class, :tails_classes, overridable: true, required: true
  attr :actions_class, :tails_classes, overridable: true, required: true

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "The arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "The slot for form actions, such as a submit button"

  def simple_form(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <.form :let={f} for={@for} as={@as} class={@class} {@rest}>
      <%= render_slot(@inner_block, f) %>
      <section :for={action <- @actions} class={@actions_class}>
        <%= render_slot(action, f) %>
      </section>
    </.form>
    """
  end

  @doc """
  Renders a button.

  Supports:

  - Any button type
  - Any anchor type
    - LivePatch
    - LiveRedirect
    - External href links

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
      <.button navigate={~p"/home"}>Home</.button>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc

  attr :confirm, :string,
    default: nil,
    doc: "Text to display in a confirm dialog before emitting click event"

  attr :csrf_token, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :href, :any

  attr :icon_name, :string,
    default: nil,
    doc:
      "The name of the icon to display (nil for none); see [`icon/1`](`Phlegethon.Components.Core.icon/1`) for details"

  attr :loading, :boolean, default: false, doc: "Display a loading spinner"
  attr :method, :string, default: "get"
  attr :navigate, :string
  attr :patch, :string
  attr :ping, :boolean, default: false, doc: "Show a ping indicator"
  attr :replace, :boolean, default: false
  attr :rest, :global, include: ~w[download hreflang referrerpolicy rel target type]

  attr :type, :string,
    default: "button",
    values: ~w[button reset submit],
    doc: "Type of the button"

  attr :case, :string,
    overridable: true,
    required: true,
    values: ~w[uppercase normal-case lowercase capitalize],
    doc: "The case of the text"

  attr :color, :string, overridable: true, required: true, doc: "The color of the button"
  attr :shape, :string, overridable: true, required: true, doc: "Shape of the button"
  attr :size, :string, overridable: true, required: true, doc: "The size of the button"
  attr :variant, :string, overridable: true, required: true, doc: "Style of button"
  attr :class, :tails_classes, overridable: true, required: true
  attr :icon_class, :tails_classes, overridable: true, required: true
  attr :ping_class, :tails_classes, overridable: true, required: true

  slot :inner_block, required: true, doc: "The content of the button"

  def button(assigns) do
    assigns
    |> assign_overridables()
    |> render_button()
  end

  defp render_button(%{href: _href} = assigns) do
    ~H"""
    <.link
      href={@href}
      replace={@replace}
      method={@method}
      csrf_token={@csrf_token}
      data-confirm={@confirm}
      data-submit={!!@confirm}
      class={@class}
      {@rest}
    >
      <Phlegethon.Components.Extra.spinner :if={@loading} overrides={@overrides} size={@size} />
      <.icon
        :if={!@loading && @icon_name}
        overrides={@overrides}
        name={@icon_name}
        class={@icon_class}
      />
      <%= render_slot(@inner_block) %>
      <%= if @ping do %>
        <span class={@ping_class <> " animate-ping opacity-75"} />
        <span class={@ping_class} />
      <% end %>
    </.link>
    """
  end

  defp render_button(%{patch: _patch} = assigns) do
    ~H"""
    <.link
      patch={@patch}
      replace={@replace}
      data-confirm={@confirm}
      data-submit={!!@confirm}
      class={@class}
      {@rest}
    >
      <Phlegethon.Components.Extra.spinner :if={@loading} overrides={@overrides} size={@size} />
      <.icon
        :if={!@loading && @icon_name}
        overrides={@overrides}
        name={@icon_name}
        class={@icon_class}
      />
      <%= render_slot(@inner_block) %>
      <%= if @ping do %>
        <span class={@ping_class <> " animate-ping opacity-75"} />
        <span class={@ping_class} />
      <% end %>
    </.link>
    """
  end

  defp render_button(%{navigate: _navigate} = assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      replace={@replace}
      data-confirm={@confirm}
      data-submit={!!@confirm}
      class={@class}
      {@rest}
    >
      <Phlegethon.Components.Extra.spinner :if={@loading} overrides={@overrides} size={@size} />
      <.icon
        :if={!@loading && @icon_name}
        overrides={@overrides}
        name={@icon_name}
        class={@icon_class}
      />
      <%= render_slot(@inner_block) %>
      <%= if @ping do %>
        <span class={@ping_class <> " animate-ping opacity-75"} />
        <span class={@ping_class} />
      <% end %>
    </.link>
    """
  end

  defp render_button(assigns) do
    ~H"""
    <button
      type={@type}
      disabled={@disabled}
      data-confirm={@confirm}
      data-submit={!!@confirm}
      class={@class}
      {@rest}
    >
      <Phlegethon.Components.Extra.spinner :if={@loading} overrides={@overrides} size={@size} />
      <.icon
        :if={!@loading && @icon_name}
        overrides={@overrides}
        name={@icon_name}
        class={@icon_class}
      />
      <%= render_slot(@inner_block) %>
      <%= if @ping do %>
        <span class={@ping_class <> " animate-ping opacity-75"} />
        <span class={@ping_class} />
      <% end %>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.


  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc

  attr :autofocus, :boolean,
    default: false,
    doc: "Enable autofocus hook to reliably focus input on mount"

  attr :checked, :boolean, doc: "The checked flag for checkbox inputs"
  attr :description, :string, default: nil
  attr :errors, :list, default: []

  attr :field, Phoenix.HTML.FormField,
    doc: "A form field struct retrieved from the form, for example: @form[:email]"

  attr :id, :any, default: nil

  attr :label, :string, default: nil
  attr :multiple, :boolean, default: false, doc: "The multiple flag for select inputs"
  attr :name, :any
  attr :options, :list, doc: "The options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :prompt, :string, default: nil, doc: "The prompt for select inputs"

  attr :type, :string,
    default: "text",
    values:
      ~w[checkbox color date datetime-local email file hidden month number password range radio search select tel text textarea time url week]

  attr :value, :any

  attr :clear_on_escape, :boolean,
    overridable: true,
    required: true,
    doc: "Clear input value on pressing Escape"

  attr :class, :tails_classes,
    overridable: true,
    required: true,
    doc: "Class of the field container element"

  attr :input_class, :tails_classes,
    overridable: true,
    required: true,
    doc: "Class of the input element"

  attr :input_check_label_class, :tails_classes,
    overridable: true,
    required: true,
    doc: "Class of the label element for a check input"

  attr :description_class, :tails_classes,
    overridable: true,
    required: true,
    doc: "Class of the field description"

  attr :rest, :global, include: ~w(autocomplete cols disabled form max maxlength min minlength
                                   pattern placeholder readonly required rows size step)
  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(assigns) do
    assigns
    |> assign_overridables()
    |> render_input()
  end

  defp render_input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div class={@class} phx-feedback-for={@name}>
      <label class={@input_check_label_class}>
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id || @name}
          name={@name}
          value="true"
          checked={@checked}
          class={@input_class}
          phx-mounted={!@autofocus || JS.focus()}
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors} overrides={@overrides}><%= msg %></.error>
    </div>
    """
  end

  defp render_input(%{type: "select"} = assigns) do
    ~H"""
    <div class={@class} phx-feedback-for={@name}>
      <.label for={@id} overrides={@overrides}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class={@input_class}
        multiple={@multiple}
        phx-mounted={!@autofocus || JS.focus()}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors} overrides={@overrides}><%= msg %></.error>
    </div>
    """
  end

  defp render_input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@class}>
      <.label for={@id} overrides={@overrides}><%= @label %></.label>
      <textarea
        id={@id || @name}
        name={@name}
        class={@input_class}
        phx-keydown={!@clear_on_escape || JS.dispatch("phlegethon:clear")}
        phx-key={!@clear_on_escape || "Escape"}
        phx-mounted={!@autofocus || JS.focus()}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <p :if={@description} class={@description_class}>
        <%= @description %>
      </p>
      <.error :for={msg <- @errors} overrides={@overrides}><%= msg %></.error>
    </div>
    """
  end

  defp render_input(assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@class}>
      <.label for={@id} overrides={@overrides}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={@input_class}
        phx-keydown={!@clear_on_escape || JS.dispatch("phlegethon:clear")}
        phx-key={!@clear_on_escape || "Escape"}
        phx-mounted={!@autofocus || JS.focus()}
        {@rest}
      />
      <p :if={@description} class={@description_class}>
        <%= @description %>
      </p>
      <.error :for={msg <- @errors} overrides={@overrides}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :class, :tails_classes, overridable: true, required: true
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <label for={@for} class={@class}>
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc

  attr :icon_name, :string,
    overridable: true,
    required: true,
    doc: "The name of the icon; see [`icon/1`](`Phlegethon.Components.Core.icon/1`) for details"

  attr :icon_class, :tails_classes, overridable: true
  attr :class, :tails_classes, overridable: true, required: true

  slot :inner_block, required: true

  def error(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <p class={@class}>
      <.icon overrides={@overrides} name={@icon_name} class={@icon_class} />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title and optional subtitle/actions.
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :class, :tails_classes, overridable: true, required: true
  attr :title_class, :tails_classes, overridable: true, required: true
  attr :subtitle_class, :tails_classes, overridable: true, required: true
  attr :actions_class, :tails_classes, overridable: true, required: true
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <header class={@class}>
      <div>
        <h1 class={@title_class}>
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class={@subtitle_class}>
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div :if={@actions != []} class={@actions_class}>
        <%= render_slot(@actions) %>
      </div>
    </header>
    """
  end

  @doc ~S"""
  Renders a simple table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :id, :string
  attr :row_click, :any, default: nil

  attr :row_id, :any,
    default: nil,
    doc: "The function for generating the row id (will automatically extract from a LiveStream)"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "The function for mapping each row before calling the :col and :action slots"

  attr :rows, :list, required: true, doc: "Supports a list or LiveStream"

  attr :class, :tails_classes, overridable: true, required: true
  attr :action_class, :tails_classes, overridable: true, required: true
  attr :action_td_class, :tails_classes, overridable: true, required: true
  attr :action_wrapper_class, :tails_classes, overridable: true, required: true
  attr :tbody_class, :tails_classes, overridable: true, required: true
  attr :td_class, :tails_classes, overridable: true, required: true
  attr :th_action_class, :tails_classes, overridable: true, required: true
  attr :th_label_class, :tails_classes, overridable: true, required: true
  attr :thead_class, :tails_classes, overridable: true, required: true
  attr :tr_class, :tails_classes, overridable: true, required: true

  slot :col, required: true do
    attr :label, :string
  end

  slot(:action, doc: "The slot for showing user actions in the last table column")

  def table(assigns) do
    assigns = assign_overridables(assigns)

    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class={@class}>
      <thead class={@thead_class}>
        <tr>
          <th :for={col <- @col} class={@th_label_class}><%= col[:label] %></th>
          <th class={@th_action_class}>
            <span class="sr-only"><%= gettext("Actions") %></span>
          </th>
        </tr>
      </thead>
      <tbody
        id={@id}
        class={@tbody_class}
        phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
      >
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class={@tr_class}>
          <td :for={col <- @col} phx-click={@row_click && @row_click.(row)} class={@td_class}>
            <%= render_slot(col, @row_item.(row)) %>
          </td>
          <td :if={@action != []} class={@action_td_class}>
            <div class={@action_wrapper_class}>
              <span :for={action <- @action} class={@action_class}>
                <%= render_slot(action, @row_item.(row)) %>
              </span>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a description list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :class, :tails_classes, overridable: true, required: true
  attr :dd_class, :tails_classes, overridable: true, required: true
  attr :dt_class, :tails_classes, overridable: true, required: true

  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <dl class={@class}>
      <%= for item <- @item do %>
        <dt class={@dt_class}><%= item.title %></dt>
        <dd class={@dd_class}><%= render_slot(item) %></dd>
      <% end %>
    </dl>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
      <.back icon_name="hero-arrow-left" navigate={~p"/"}>
        Go back to the about page.
      </.back>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc

  attr :icon_name, :string,
    overridable: true,
    required: true,
    doc: "The name of the icon; see [`icon/1`](`Phlegethon.Components.Core.icon/1`) for details"

  attr :class, :tails_classes, overridable: true, required: true
  attr :icon_class, :tails_classes, overridable: true, required: true

  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <.link navigate={@navigate} class={@class}>
      <.icon overrides={@overrides} name={@icon_name} class={@icon_class} />
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  @icons_dir Path.join(File.cwd!(), "priv/hero_icons")
  @outline [@icons_dir, "optimized/24/outline"]
           |> Path.join()
           |> File.ls!()
           |> Enum.map(fn name ->
             "hero-#{Path.basename(name, ".svg")}"
           end)

  @solid [@icons_dir, "optimized/24/solid"]
         |> Path.join()
         |> File.ls!()
         |> Enum.map(fn name ->
           "hero-#{Path.basename(name, ".svg")}-solid"
         end)

  @mini [@icons_dir, "optimized/20/solid"]
        |> Path.join()
        |> File.ls!()
        |> Enum.map(fn name ->
          "hero-#{Path.basename(name, ".svg")}-mini"
        end)

  @icon_name_options Enum.zip([@outline, @solid, @mini])
                     |> Enum.flat_map(fn {o, s, m} -> [o, s, m] end)

  @doc """
  Renders an icon.

  > #### Tip {: .info}
  >
  > See the [Heroicons website](https://heroicons.com/) to preview/search the available icons.

  Additionally, there are long-term plans to add more icon libraries.

  ## Examples

  ```heex
  <.icon name="hero-arrow-left" />
  ```
  ```heex
  <.icon name="hero-arrow-right-solid" class="block" />
  ```
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :class, :tails_classes, overridable: true, required: true

  attr :name, :string,
    required: true,
    values: @icon_name_options,
    doc: "The icon name"

  attr :rest, :global,
    doc: "The arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  def icon(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <span class={[@name, @class]} />
    """
  end
end
