# Load secrets from the encrypted JSON file at startup
if type -q secret
    secret load
end
