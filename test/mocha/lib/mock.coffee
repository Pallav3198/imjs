nock = require 'nock'
path = require 'path'
fs   = require 'fs'
url  = require 'url'

{unitTests} = require './segregation'

TESTMODEL_URL_VAR = 'TESTMODEL_URL'
root = process.env[TESTMODEL_URL_VAR]

# IMPORTANT: RESPONSE_FOLDER must be present relative to the current directory
RESPONSE_FOLDER = path.join __dirname, 'responses'
META_FILE = '_meta.json'

# Helper function to record the nock responses and store them
# fileName (string) -> Where you want to store in the responses, 
#   ideally should end in 'json'
# before, after (function) -> before and after hooks of the Unit Test, to which
#   one needs to attatch the recorder to
recordResponses = (fileName, before, after) ->
    before ->
        nock.recorder.rec
            output_objects: true
    
    after ->
        nock.restore()
        nockCallObjects = nock.recorder.play()
        fs.writeFile fileName, JSON.stringify(nockCallObjects), console.error

parseUrl = (relativeUrl) ->
    urlObj = url.parse relativeUrl
    pathname = urlObj.pathname
    querystring = urlObj.search
    fragment = urlObj.hash

    return 
        pathname: pathname
        querystring: querystring
        fragment: fragment



# Helper function to find the file storing the responses,
# along with the query parameter specified.
# url (string) -> Must be relative to the 'root', eg. '/service/model?format=json' is a valid 
#   part of the url, note the leading slash. Initial part of the path used will be 'root', i.e.
#   concatenation of 'root' and the 'url' must provide the path of the query to be resolved
findResponse = (url) ->
    parsedUrl = parseUrl url
    {pathname, querystring} = parsedUrl
    # Convert the pathname to the folder name by replacing '/' with OS specific delimiter
    folderName = path.join RESPONSE_FOLDER, pathname.split('/').join path.sep
    metaFileName = path.join folderName, META_FILE
    responsesData = JSON.parse fs.readFileSync metaFileName
    responseFile = null
    for k,v of responsesData
        if k is querystring
            responseFile = path.join folderName, v.file 
    return responseFile
    
# Function which specifies if mocks should be setup or not, currenty it's functionality
# is redundant, but might change later in case the logic when to setup unit test changes
shouldSetupMock = ->
    unitTests()

setupMock = (url) ->
    if not shouldSetupMock()
        return
    responseFile = findResponse url
    nock.load responseFile

module.exports =
    recordResponses: recordResponses
    findResponse: findResponse
    setupMock: setupMock