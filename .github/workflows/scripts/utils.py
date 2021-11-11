# coding: utf-8
import re

def get_version_from_pubspec(pubspec_yaml):
    with open(pubspec_yaml, 'r') as f:
        repatter = re.compile('^version: ([0-9.]+)')
        for row in f:
            result = repatter.search(row)
            if result:
                return result.group(1)


def get_next_version(version):
    def mapping(i_n):
        if i_n[0] == 0:
            return i_n[1]
        elif i_n[0] == 1:
            return str(int(i_n[1]) + 1)
        else:
            return '0'

    vers = map(mapping, enumerate(version.split('.')))
    return '.'.join(vers)

def override_version(pubspec_yaml, version):
    with open(pubspec_yaml, 'r') as f:
        text = re.sub(r'refs/tags/[0-9.]+', 'refs/tags/%s' % version, f.read())
    with open(pubspec_yaml, 'w') as f:
        f.write(text)

    return version