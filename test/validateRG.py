#!/usr/bin/python

# Backlog
# Review

import argparse
import json
import datetime
from pprint import pprint

# Handle input
parser = argparse.ArgumentParser()
parser.add_argument("TargetRG_JSON", help="The deployed resource group JSON file")
parser.add_argument("DesiredState_JSON", help="The desired state definition JSON file used for validation")

args = parser.parse_args()
print("\nRunning Validate Resource Group against desired state.")


# Retrieve JSON
with open(args.TargetRG_JSON) as data_file: 
	targetRGJSON = json.load(data_file)
	
with open(args.DesiredState_JSON) as data_file:    
    dsRGJSON = json.load(data_file)	
	
# Input an Array
# Each array entry is a Dict.

def is_number(s):
	try:
		float(s)
		return True
	except ValueError:
		return False

# Go through JSON Dictionary and return a Dictionary with a count for each deployed asset.
def getAssetCount(data):
	tmpDict = {}
	for i in data:
		#print("i[type]:",i['type'])
		if (i['type'] in tmpDict):
			#print("updating entry")
			tmpDict[i['type']] = tmpDict[i['type']] + 1
			#print("tmpDict[",i['type'],"]=",tmpDict[i['type']] )
		else:
			#print("adding entry",i['type'])
			tmpDict[i['type']] = 1
			#print("tmpDict[",i['type'],"]=",tmpDict[i['type']] )
		#print("\n ")
	return tmpDict
	
	
# Compare the deployed assets of the targeted deployement with the desired state.
# 4 potential failures detected
#   Scenario where target deployment has the asset but the count is off. 
#   Failure 1: Target has less then specified # of deployments 
#   Failure 2: Target has more then specified # of deployments
#   Failure 3: Target is missing the deployment
#   Failure 4: Target has extra assets deployed not in desired state
#   
def compareAssets(refDict, tarDict):
	tmpDict = {}
	#keysRef = refDict.keys()
	#keysTar = tarDict.keys()
	for x in refDict.keys():
		if (x in tarDict):
			if(refDict[x] != tarDict[x]):
				tmpDict[x]= refDict[x] - tarDict[x]     # Failure: Deployment exist but count is off
		else:
			tmpDict[x] = "missing"  # Failure : Deployment is missing
			
	for y in tarDict.keys():
		if (y not in refDict):
			tmpDict[y] = "extra"    # Failure : Extra asset is in targeted deployment
	return tmpDict
	
# Generate a JSON & optional command line text report of the findings
def generateReport(reportDict, refDict):
	tmpJSON = {}
	resultList = []	
	tmpJSON["name"] = "Resource Group Validation Results"
	tmpJSON["validate"] = targetRGJSON["name"]
	tmpJSON["baseline"] = args.DesiredState_JSON
	tmpJSON["date"] = '{:%Y-%m-%d %H:%M:%S}'.format(datetime.datetime.now())
	if (len(reportDict) > 0):
		tmpJSON["status"] = "Failed: Deployment doesn't match"
		countList= []
		missingList = []
		extraList = []
		countDict = {}
		missingDict = {}
		extraDict = {}
		print("Failed: Deployments do not match:")
		for k,v  in reportDict.items():
			reasonDict = {}
			entryDict = {}
			if (is_number(reportDict[k])):
				reasonDict["count"] = str(abs(v))
				if (v > 0):									
					# Report the number of missing deployments
					reasonDict["issue"] = "missing deployments"
					
					print("\t",k,"is missing",v,"deployments.")
				else: 
					# Report the number of extra deployments
					reasonDict["issue"] = "extra deployments"
					print("\t",k,"has",abs(v),"extra deployments.")
				entryDict[k] = reasonDict
				countList.append(entryDict)
			else:		
				# Asset is missing completely Or it's extra Asset			
				if (v == "missing"):
					reasonDict["count"] = 0
					reasonDict["issue"] = "no deployment found!"
					entryDict[k] = reasonDict
					missingList.append(entryDict)
				elif (v== "extra"):
					reasonDict["issue"] = "Extra Azure asset found."
					entryDict[k] = reasonDict					
					extraList.append(entryDict)
				print("\t",k,v)
		countDict["count"] = countList
		missingDict["missing"] = missingList
		extraDict["extra"] = extraList
		resultList.append(countDict)
		resultList.append(missingDict)
		resultList.append(extraDict)
	else:
		tmpJSON["status"] ="Passed: Deployments match"
		print("Passed: Deployment matches desired state!")
		for k,v in refDict.items():
			passEntry = {}
			passEntry[k] = str(v)
			resultList.append(passEntry)
			print("\t",k,"has",v,"deployed")
			
	tmpJSON["results"] = resultList
	return tmpJSON
	
			
		
# parse through JSON to count assets	
tgDict = getAssetCount(targetRGJSON["resources"])
dsDict = getAssetCount(dsRGJSON["resources"])

# compare assets to find issues
tmpDict = compareAssets(dsDict,tgDict)
print("\n",'-'*10,"Results",'-'*10)

# generate json output
finalJSON = generateReport(tmpDict,dsDict)
pprint(finalJSON)


