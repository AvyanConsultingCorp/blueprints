@ECHO OFF
SETLOCAL

ECHO Run through all the desired state test


ECHO Single VM Test ====================================================================================
python validateRG.py unittestjson\test-singlevm-extra#storage.json	singlevm-desiredstate.json
python validateRG.py unittestjson\test-singlevm-missing#storage.json	singlevm-desiredstate.json
python validateRG.py unittestjson\test-singlevm-missingNIC.json		singlevm-desiredstate.json
python validateRG.py unittestjson\test-singlevm-unspecifiedasset.json	singlevm-desiredstate.json

ECHO Multi-VM Test =====================================================================================
python validateRG.py unittestjson\test-multiplevm-extra#NIC.JSON	multivm-desiredstate.json
python validateRG.py unittestjson\test-multiplevm-missing#NIC.JSON	multivm-desiredstate.json
python validateRG.py unittestjson\test-multiplevm-missingNIC.JSON	multivm-desiredstate.json
python validateRG.py unittestjson\test-multiplevm-unpsecifiedasset.JSON	multivm-desiredstate.json

ECHO 3-Tier Test =======================================================================================
python validateRG.py unittestjson\test-3tier-extra#NIC.json     3tier-desiredstate.json
python validateRG.py unittestjson\test-3tier-missing#NIC.json	3tier-desiredstate.json
python validateRG.py unittestjson\test-3tier-missingNIC.json	3tier-desiredstate.json
python validateRG.py unittestjson\test-3tier-unspecifiedasset.json	3tier-desiredstate.json

