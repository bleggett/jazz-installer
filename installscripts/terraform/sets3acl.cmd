set BUCKET_NAME=%1
aws s3api put-bucket-acl --bucket %BUCKET_NAME% --grant-full-control id=78d7d8174c655d51683784593fe4e6f74a7ed3fae3127d2beca2ad39e4fdc79a,uri=http://acs.amazonaws.com/groups/s3/LogDelivery,uri=http://acs.amazonaws.com/groups/global/AuthenticatedUsers --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers   --grant-read-acp uri=http://acs.amazonaws.com/groups/global/AllUsers