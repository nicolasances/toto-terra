gcloud beta dns --project=pleggit-prod record-sets transaction start --zone="pleggit-dns-zone"

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 1. Sites 
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
gcloud beta dns --project=pleggit-prod record-sets transaction add ghs.googlehosted.com. --name="money.dev.toto.nimatz.com." --ttl="3600" --type="CNAME" --zone="nimatz.com"
gcloud beta dns --project=pleggit-prod record-sets transaction add ghs.googlehosted.com. --name="money.toto.nimatz.com." --ttl="3600" --type="CNAME" --zone="nimatz.com"

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 2. APIs 
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 2.1. Expenses APIs
gcloud beta dns --project=pleggit-prod record-sets transaction add ghs.googlehosted.com. --name="expenses.dev.api.toto.nimatz.com." --ttl="3600" --type="CNAME" --zone="nimatz.com"
gcloud beta dns --project=pleggit-prod record-sets transaction add ghs.googlehosted.com. --name="expenses.dev.api.toto.nimatz.com." --ttl="3600" --type="CNAME" --zone="nimatz.com"
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

gcloud beta dns --project=pleggit-prod record-sets transaction execute --zone="pleggit-dns-zone"
