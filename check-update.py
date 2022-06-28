#!/bin/python
# Reads a private binary-aur arch repository database
# and checks if the AUR contains updated versions of packages
import json
#import subprocess
import tarfile
from urllib.request import urlopen


GZIPPEDDB = "/var/lib/pacman/sync/stash.db"

class Package:
	def __init__(self, name, version):
		self.name = name
		self.version = version
		self.aurver = ''

	def aurversion(self, version):
		self.aurver = version


class Packages:
	def __init__(self):
		self.pkgarray = []

	def pkgs(self):
		namearray = []
		for i in self.pkgarray:
			namearray.append(i.name)
		return(namearray)

	def addpkg(self, Package):
		self.pkgarray.append(Package)


def api_url(pkgs):
	#pkgs: array
	#https://wiki.archlinux.org/title/Aurweb_RPC_interface
	baseurl = "https://aur.archlinux.org/rpc/?v=5&type=info&arg[]="
	return(baseurl + "&arg[]=".join(pkgs))

#here for backup
#def vercmp_isnewer(new, old):
#	#new: string, old: string
#	#epoch:version-rel
#	#Not working properly if the AUR doesn't have the package we're checking
#	vercmp = subprocess.run(["vercmp", new, old], capture_output=True)
#	return(vercmp.stdout > b'0\n')


def isnewer(new, old):
	#new: string, old: string
	#Will not work properly in some niche cases, ie epoch additions or alphanumerics
	#vercmp_isnewer uses the pacman version comparison utility
	return(new > old)

def readpkgdesc(descfile):
	#descfile: file handle
	reading = True
	while(reading):
		if (descfile.readline() == b'%NAME%\n'):
			name = descfile.readline().decode().strip()
		elif (descfile.readline() == b'%VERSION%\n'):
			version = descfile.readline().decode().strip()
		elif (descfile.readline() == b''):
			reading = False
	return(Package(name, version))


def loadcurrent(dbfile_uri, Packages):
	#dbfile_uri: string, Packages: Packages handle
	db = tarfile.TarFile.gzopen(dbfile_uri)
	for file in db:
		if file.isfile():
			buf = db.extractfile(file)
			Packages.addpkg(readpkgdesc(buf))
			buf.close()
	db.close()


def ratelimit():
	# I'm sure at some point a ratelimiter will be needed
	# be it for queries per second or size of query.
	return 0

def getaurdata(pkgs):
	#pkgs: array
	#
	#for debug/and testing use the hardcoded file
	#import io at file head
	#
	#buf = io.FileIO('auroutput.json') # exact output from an AUR query
	#pydat = json.loads(buf.readall().decode())
	#buf.close()
	#
	buf = urlopen(api_url(pkgs))
	pydat = json.loads(buf.read())
	return(pydat)

def debug(pkgdb):
	DEBUGSTR = "DEBUG: {} Current: {}, AUR: {}"
	for i in pkgdb.pkgarray:
		print(DEBUGSTR.format(i.name, i.version, i.aurver))

def addaurver(Packages, name, version):
	for pkg in Packages.pkgarray:
		if (pkg.name == name):
			pkg.aurversion(version)

def loadaur(Packages):
	#Packages: Packages handle
	#add AUR version info to Package info
	data = getaurdata(Packages.pkgs())
	for i in data['results']:
		addaurver(Packages, i['Name'], i['Version'])

def checknewer(Packages):
	AURNEWER = "AUR Version for {} is {}, current version is {}"
	NONEW = "No newer versions in AUR"
	newercount = 0
	for pkg in Packages.pkgarray:
		if isnewer(pkg.aurver, pkg.version):
			print(AURNEWER.format(pkg.name, pkg.aurver, pkg.version))
			newercount += 1
	if (newercount == 0):
		print(NONEW)

def main():
	pkgdb = Packages()
	loadcurrent(GZIPPEDDB, pkgdb)
	loadaur(pkgdb)
	checknewer(pkgdb)
	#debug(pkgdb)
	##TODO Rate limit AUR requests
	##TODO Options: full table, quiet on nonew


if __name__ == '__main__':
	main()
