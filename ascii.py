import requests
from PIL import Image

x = requests.get("url")
print(Image.__version__)
lines = []
with open("ascii.txt", "r") as f:
    lines = f.readlines()

with open("ascii-out.txt", "w") as f:
    for line in lines:
        f.write(f"'{line.strip('\n')}',\n")
