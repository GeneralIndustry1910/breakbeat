"""Build the phone-friendly Breakbeat TouchOSC layout from Toga's grid layout."""

from copy import deepcopy
from pathlib import Path
import sys
import uuid
import zlib
import xml.etree.ElementTree as ET


SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".tmp_toga_reference/toga.tosc")
OUTPUT = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("breakbeat.tosc")


def property_value(node, key):
    prop = node.find(f"./properties/property[key='{key}']")
    if prop is None:
        raise ValueError(f"missing property: {key}")
    return prop.find("value")


def property_text(node, key):
    value = property_value(node, key)
    return value.text or ""


document = ET.fromstring(zlib.decompress(SOURCE.read_bytes()))
page = document.find("node")
children = page.find("children")
nodes = list(children.findall("node"))

page_frame = property_value(page, "frame")
page_frame.find("w").text = "1320"

grid = next(node for node in nodes if property_text(node, "name") == "togagrid")
connection = next(node for node in nodes if property_text(node, "name") == "toga_connection")
arc_group = next(node for node in nodes if property_text(node, "name") == "togaarc/knob1")
property_value(grid, "frame").find("x").text = "60"
property_value(connection, "frame").find("x").text = "1265"

# Give the 64 drum cells a receive-only color route. Norns sends color names
# so the layout can distinguish single, double, and four-pulse gate modes.
color_script = """function onReceiveOSC(message)
  local names = {
    gray = Color(0.22, 0.22, 0.22, 1),
    yellow = Color(1.00, 0.80, 0.10, 1),
    blue = Color(0.10, 0.55, 1.00, 1),
    green = Color(0.15, 0.95, 0.35, 1)
  }
  local value = message[2][1] and message[2][1].value
  if names[value] then self.color = names[value] end
end"""

for button in list(grid.find("children").findall("node"))[:64]:
    properties = button.find("properties")
    script_property = ET.SubElement(properties, "property", {"type": "s"})
    ET.SubElement(script_property, "key").text = "script"
    ET.SubElement(script_property, "value").text = color_script

    color_message = ET.SubElement(button.find("messages"), "osc")
    for key, value in (("enabled", "1"), ("send", "0"), ("receive", "1"),
                       ("feedback", "0"), ("noDuplicates", "0"),
                       ("connections", "1111111111")):
        ET.SubElement(color_message, key).text = value
    triggers = ET.SubElement(color_message, "triggers")
    trigger = ET.SubElement(triggers, "trigger")
    ET.SubElement(trigger, "var").text = "touch"
    ET.SubElement(trigger, "condition").text = "ANY"
    path = ET.SubElement(color_message, "path")
    for kind, value in (("CONSTANT", "/"), ("PROPERTY", "parent.name"),
                        ("CONSTANT", "/"), ("PROPERTY", "name"),
                        ("CONSTANT", "/color")):
        partial = ET.SubElement(path, "partial")
        ET.SubElement(partial, "type").text = kind
        ET.SubElement(partial, "conversion").text = "STRING"
        ET.SubElement(partial, "value").text = value
        ET.SubElement(partial, "scaleMin").text = "0"
        ET.SubElement(partial, "scaleMax").text = "1"
    ET.SubElement(color_message, "arguments")

# Remove Toga's four encoder groups. The connection button and 16x8 grid remain.
for node in nodes:
    if property_text(node, "name").startswith("togaarc/"):
        children.remove(node)

# Reuse Toga's proven button messaging, but present it as four broad strips.
controls = deepcopy(grid)
controls.set("ID", str(uuid.uuid4()))
controls.set("type", "GROUP")
# Color feedback belongs only to the original drum grid, not to the control
# buttons cloned from it below.
for button in controls.find("children").findall("node"):
    for prop in list(button.findall("./properties/property")):
        if prop.findtext("key") == "script":
            button.find("properties").remove(prop)
    messages = button.find("messages")
    for message in list(messages.findall("osc")):
        if message.findtext("send") == "0":
            messages.remove(message)
property_value(controls, "name").text = "breakbeatcontrol"
property_value(controls, "background").text = "0"
property_value(controls, "outline").text = "0"
property_value(controls, "interactive").text = "0"
container_color = property_value(controls, "color")
container_color.find("r").text = "0"
container_color.find("g").text = "0"
container_color.find("b").text = "0"
frame = property_value(controls, "frame")
frame.find("x").text = "60"
frame.find("y").text = "0"
frame.find("h").text = "240"

control_children = controls.find("children")
buttons = list(control_children.findall("node"))
for button in buttons[64:]:
    control_children.remove(button)

row_colors = (
    (0.20, 0.95, 0.45),  # probability
    (0.10, 0.75, 1.00),  # mutation
    (1.00, 0.35, 0.65),  # chaos
    (0.65, 0.45, 1.00),  # loop length
)

for index, button in enumerate(buttons[:64]):
    button.set("ID", str(uuid.uuid4()))
    row = index // 16
    color = property_value(button, "color")
    red, green, blue = row_colors[row]
    color.find("r").text = str(red)
    color.find("g").text = str(green)
    color.find("b").text = str(blue)


def make_lane_buttons(name, x, color_values, button_type=0):
    group = deepcopy(controls)
    group.set("ID", str(uuid.uuid4()))
    property_value(group, "name").text = name
    group_frame = property_value(group, "frame")
    group_frame.find("x").text = str(x)
    group_frame.find("y").text = "260"
    group_frame.find("w").text = "60"
    group_frame.find("h").text = "240"

    group_children = group.find("children")
    lane_buttons = list(group_children.findall("node"))
    for button in lane_buttons[4:]:
        group_children.remove(button)

    for lane, button in enumerate(lane_buttons[:4]):
        button.set("ID", str(uuid.uuid4()))
        property_value(button, "name").text = str(lane + 1)
        property_value(button, "buttonType").text = str(button_type)
        button_frame = property_value(button, "frame")
        button_frame.find("x").text = "3"
        button_frame.find("y").text = str(3 + (lane * 60))
        button_frame.find("w").text = "54"
        button_frame.find("h").text = "54"
        button_color = property_value(button, "color")
        button_color.find("r").text = str(color_values[0])
        button_color.find("g").text = str(color_values[1])
        button_color.find("b").text = str(color_values[2])
    return group


def make_top_button(name, x, color_values):
    group = make_lane_buttons(name, x, color_values, 1)
    group_frame = property_value(group, "frame")
    group_frame.find("y").text = "10"
    group_frame.find("w").text = "180"
    group_frame.find("h").text = "60"
    group_children = group.find("children")
    lane_buttons = list(group_children.findall("node"))
    for button in lane_buttons[1:]:
        group_children.remove(button)
    button_frame = property_value(lane_buttons[0], "frame")
    button_frame.find("w").text = "174"
    return group


def make_swing_fader():
    group = deepcopy(arc_group)
    group.set("ID", str(uuid.uuid4()))
    property_value(group, "name").text = "breakbeatswing"
    group_frame = property_value(group, "frame")
    group_frame.find("x").text = "1020"
    group_frame.find("y").text = "90"
    group_frame.find("w").text = "280"
    group_frame.find("h").text = "70"

    fader = group.find("./children/node")
    fader.set("ID", str(uuid.uuid4()))
    fader.set("type", "FADER")
    property_value(fader, "name").text = "fader"
    fader_frame = property_value(fader, "frame")
    fader_frame.find("x").text = "10"
    fader_frame.find("y").text = "10"
    fader_frame.find("w").text = "260"
    fader_frame.find("h").text = "50"
    color = property_value(fader, "color")
    color.find("r").text = "1.0"
    color.find("g").text = "0.70"
    color.find("b").text = "0.15"
    properties = fader.find("properties")
    for key, type_name, value in (("bar", "b", "1"), ("barDisplay", "i", "2"), ("centered", "b", "0")):
        prop = ET.SubElement(properties, "property", {"type": type_name})
        ET.SubElement(prop, "key").text = key
        ET.SubElement(prop, "value").text = value
    return group


roll_buttons = make_lane_buttons("breakbeatroll", 0, (1.0, 0.55, 0.10))
mute_buttons = make_lane_buttons("breakbeatmute", 1020, (1.0, 0.15, 0.15), 1)
probability_buttons = make_lane_buttons("breakbeatprobability", 1080, (0.20, 0.95, 0.45), 1)
mutation_buttons = make_lane_buttons("breakbeatmutation", 1140, (0.10, 0.75, 1.00), 1)
chaos_buttons = make_lane_buttons("breakbeatchaos", 1200, (1.00, 0.35, 0.65), 1)
clear_buttons = make_lane_buttons("breakbeatclear", 1260, (0.95, 0.95, 0.95))
cv_button = make_top_button("breakbeatcv", 1020, (0.10, 0.75, 1.00))
swing_fader = make_swing_fader()

children.insert(0, controls)
children.insert(1, roll_buttons)
children.insert(2, mute_buttons)
children.insert(3, probability_buttons)
children.insert(4, mutation_buttons)
children.insert(5, chaos_buttons)
children.insert(6, clear_buttons)
children.insert(7, cv_button)
children.insert(8, swing_fader)
xml = ET.tostring(document, encoding="utf-8", xml_declaration=True)
OUTPUT.write_bytes(zlib.compress(xml, level=9))
print(f"wrote {OUTPUT} ({len(xml)} bytes uncompressed)")

