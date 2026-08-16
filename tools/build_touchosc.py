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

grid = next(node for node in nodes if property_text(node, "name") == "togagrid")

# Remove Toga's four encoder groups. The connection button and 16x8 grid remain.
for node in nodes:
    if property_text(node, "name").startswith("togaarc/"):
        children.remove(node)

# Reuse Toga's proven button messaging, but present it as four broad strips.
controls = deepcopy(grid)
controls.set("ID", str(uuid.uuid4()))
property_value(controls, "name").text = "breakbeatcontrol"
frame = property_value(controls, "frame")
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

children.insert(0, controls)
xml = ET.tostring(document, encoding="utf-8", xml_declaration=True)
OUTPUT.write_bytes(zlib.compress(xml, level=9))
print(f"wrote {OUTPUT} ({len(xml)} bytes uncompressed)")

