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
page_frame.find("w").text = "1080"

grid = next(node for node in nodes if property_text(node, "name") == "togagrid")
connection = next(node for node in nodes if property_text(node, "name") == "toga_connection")
property_value(grid, "frame").find("x").text = "60"
property_value(connection, "frame").find("x").text = "1025"

# Remove Toga's four encoder groups. The connection button and 16x8 grid remain.
for node in nodes:
    if property_text(node, "name").startswith("togaarc/"):
        children.remove(node)

# Reuse Toga's proven button messaging, but present it as four broad strips.
controls = deepcopy(grid)
controls.set("ID", str(uuid.uuid4()))
controls.set("type", "GROUP")
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


def make_lane_buttons(name, x, color_values):
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


roll_buttons = make_lane_buttons("breakbeatroll", 0, (1.0, 0.55, 0.10))
mute_buttons = make_lane_buttons("breakbeatmute", 1020, (1.0, 0.15, 0.15))

children.insert(0, controls)
children.insert(1, roll_buttons)
children.insert(2, mute_buttons)
xml = ET.tostring(document, encoding="utf-8", xml_declaration=True)
OUTPUT.write_bytes(zlib.compress(xml, level=9))
print(f"wrote {OUTPUT} ({len(xml)} bytes uncompressed)")

