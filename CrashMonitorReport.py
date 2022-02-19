
from sys import exit
from time import sleep
import tempfile
import os.path
import argparse
import json
import re
import requests
import yadisk

parser = argparse.ArgumentParser(description='CrashMonitorReport', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('--ytoken', help='ytoken')
parser.add_argument('--gtoken', help='gtoken')
parser.add_argument('--file', help='file')
parser.add_argument('--md5', help='md5')
parser.add_argument('--owner', help='owner')
parser.add_argument('--repo', help='repo')
parser.add_argument('--ver', help='ver')
args = parser.parse_args()

iytoken = args.ytoken
igtoken = args.gtoken
ifile = args.file
imd5 = args.md5
iowner = args.owner
irepo = args.repo
iver = args.ver


def check_issue(owner, repo, title):
    headers = {
        'accept': 'application/vnd.github.v3+json',
    }
    page = 1
    error = 0
    while True:
        response = requests.get('https://api.github.com/repos/%s/%s/issues?state=open&labels=crashmonitor&page=%s' % (owner, repo, page), headers=headers)
        if response.status_code == 200:
            if re.search(r'title', response.text.lower()):
                jdata = response.json()
                page += 1
                error = 0
                for i in jdata:
                    if i['title'] == title:
                        return i['number']
            else:
                return 0
        else:
            if error >= 3:
                print(response.status_code)
                exit(5)
            else:
                sleep(5)
                error += 1


def create_issue(owner, repo, title, token):
    if re.search(r'[0-9A-Fa-f]{8}', title):
        labels = ['crashmonitor', 'sfall']
    else:
        labels = ['crashmonitor', 'other']
    headers = {
        'authorization': 'token %s' % token,
        'accept': 'application/vnd.github.v3+json',
    }
    data = {'title': title, 'body': 'reserved', 'labels': labels}
    error = 0
    while True:
        response = requests.post('https://api.github.com/repos/%s/%s/issues' % (owner, repo), headers=headers, data=json.dumps(data))
        if response.status_code == 201:
            jdata = response.json()
            error = 0
            return jdata['number']
        else:
            if error >= 3:
                print(response.status_code)
                exit(6)
            else:
                sleep(5)
                error += 1


def create_comment(owner, repo, issue_number, body, token):
    headers = {
        'authorization': 'token %s' % token,
        'accept': 'application/vnd.github.v3+json',
    }
    data = {'body': body}
    error = 0
    while True:
        response = requests.post('https://api.github.com/repos/%s/%s/issues/%s/comments' % (owner, repo, issue_number), headers=headers, data=json.dumps(data))
        if response.status_code == 201:
            error = 0
            return True
        else:
            if error >= 3:
                print(response.status_code)
                exit(7)
            else:
                sleep(5)
                error += 1


if os.path.isfile(ifile):
    if os.path.isfile(re.sub(r'\.7z$', r'_crash.txt', ifile)):
        if os.path.isfile(re.sub(r'\.7z$', r'_report.txt', ifile)):
            with tempfile.TemporaryDirectory() as tdir:
                disk = yadisk.YaDisk()
                disk.download_public(iytoken, r''.join([tdir, r'\temp.txt']))
                with open(r''.join([tdir, r'\temp.txt'])) as file:
                    iytoken = file.readline().split(r';')
            for ver in iytoken:
                if ver == iver:
                    break
            else:
                exit(0)
            disk = yadisk.YaDisk(token=iytoken[0])
            disk.upload(ifile, r'app:/%s' % re.sub(r'^(?:.*)([0-9]{8}\_[0-9]{6}\.7z)$', r'\1', ifile), overwrite=True)
            disk.publish(r'app:/%s' % re.sub(r'^(?:.*)([0-9]{8}\_[0-9]{6}\.7z)$', r'\1', ifile))
            iurl = disk.get_meta(r'app:/%s' % re.sub(r'^(?:.*)([0-9]{8}\_[0-9]{6}\.7z)$', r'\1', ifile)).public_url
            if re.search(r'^https', iurl) and disk.get_meta(r'app:/%s' % re.sub(r'^(?:.*)([0-9]{8}\_[0-9]{6}\.7z)$', r'\1', ifile)).md5.lower() == imd5.lower():
                with open(re.sub(r'\.7z$', r'_crash.txt', ifile)) as file:
                    ititle = re.sub(r'^(.{1,200})(?:.*)$', r'\1', max(file.readlines(), key=len))
                with open(re.sub(r'\.7z$', r'_report.txt', ifile)) as file:
                    ibody = '`%s`\n[%s](%s)' % (file.read(), re.sub(r'^(?:.*)([0-9]{8}\_[0-9]{6}\.7z)$', r'\1', ifile), iurl)
                iissue = -1
                iissue = check_issue(iowner, irepo, ititle)
                if iissue == -1:
                    disk.remove(r'app:/%s' % re.sub(r'^(?:.*)([0-9]{8}\_[0-9]{6}\.7z)$', r'\1', ifile))
                    exit(4)
                elif iissue == 0:
                    iissue = create_issue(iowner, irepo, ititle, igtoken)
                if create_comment(iowner, irepo, iissue, ibody, igtoken):
                    exit(0)
            else:
                disk.remove(r'app:/%s' % re.sub(r'^(?:.*)([0-9]{8}\_[0-9]{6}\.7z)$', r'\1', ifile))
                exit(3)


exit(2)
