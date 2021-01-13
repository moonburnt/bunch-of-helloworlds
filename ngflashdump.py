## Script to locally download flash games from newgrounds

## Imports
import requests
import logging
from re import search
import argparse
from os import makedirs
from sys import exit

## Global vars n stuff
DEFAULT_DOWNLOAD_DIRECTORY="."

# Custom logger
log = logging.getLogger(__name__)
#log.setLevel(logging.INFO)
#log.setLevel(logging.DEBUG)
log.setLevel(logging.WARNING)
handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter(fmt='[%(asctime)s][%(name)s][%(levelname)s] %(message)s', datefmt='%H:%M:%S'))
log.addHandler(handler)

## Functions
def get_page_source(link):
    '''Receives str(webpage url), returns raw content of said page'''
    log.debug(f"Fetching page content from {link}")
    page = requests.get(link, timeout = 100)
    page.raise_for_status()

    return page.text

def download_file(link):
    '''Receives str(link to download file), saves file to DOWNLOAD_DIRECTORY'''
    log.debug(f"Fetching file from {link}")
    data = requests.get(link, timeout = 100)
    data.raise_for_status()

    log.debug(f"Trying to determine filename")
    fn = link.rsplit('/', 1) #this aint perfect, coz link may contain some garbage such as id after file name
    filename = str(fn[1])
    save_path = DOWNLOAD_DIRECTORY+"/"+filename

    log.debug(f"Attempting to save file as {save_path}")
    with open(save_path, 'wb') as f:
        f.write(data.content)
    log.info(f"Successfully saved {filename} as {save_path}")

def get_download_link(page):
    '''Receives str(webpage's html content), returns link to download file'''
    log.debug(f"Searching for expression in html source")
    r = search('swf: "(.*)", ', page_html)
    raw_link = r.group(1)
    log.debug(f"Found download link link: {raw_link}, attempting to cleanup")

    cl = raw_link.rsplit("?", 1) #avoiding the issue described in comment on line 39
    clean_link = str(cl[0])
    log.debug(f"Clean link is: {clean_link}")

    return clean_link

## Code

# Argparse shenanigans
ap = argparse.ArgumentParser()
ap.add_argument("url", help="URL of newgrounds page, from which you want to download swf game", type=str)
ap.add_argument("-d", "--directory", help="Custom path to downloads directory", type=str)
args = ap.parse_args()

if args.directory:
    log.debug(f"Attempting to set downloads directory to {args.directory}")
    try:
        makedirs(args.directory, exist_ok=True)
    except Exception as e:
        log.error(f"An error has happend while trying to create downloads directory: {e}")
        print(f"Couldnt set custom downloads directory. Are you sure provided path is correct?")
        exit(1)
    print(f"Downloads directory has been set to {args.directory}")
    DOWNLOAD_DIRECTORY = args.directory
else:
    print(f"Downloads directory isnt set, will use default: {DEFAULT_DOWNLOAD_DIRECTORY}")
    DOWNLOAD_DIRECTORY = DEFAULT_DOWNLOAD_DIRECTORY
DOWNLOAD_URL = args.url

print(f"Attempting to download flash game from {DOWNLOAD_URL}")
try:
    page_html = get_page_source(DOWNLOAD_URL)
except Exception as e:
    log.error(f"Some unfortunate error has happend: {e}")
    print(f"Couldnt fetch provided url. Are you sure your link is correct?")
    exit(1)

try:
    link = get_download_link(page_html)
except Exception as e:
    log.error(f"Some unfortunate error has happend: {e}")
    print("Couldnt find download link :( Are you sure this is a flash game?")
    exit(1)

try:
    download_file(link)
except Exception as e:
    log.error(f"Some unfortunate error has happend: {e}")
    print("Couldnt download the game :( Please double-check your internet connection and try again")
    exit(1)

print("Done")
exit(0)
