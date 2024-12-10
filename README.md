# Helm repository in S3

## how to push new helm chart to repository (example)

```shell
mkdir tmp
# download current repository index
curl "https://example.com/my-repo/index.yaml" -o ./tmp/curr.yaml
# package chart
helm package ~/path/to/chart -d ./tmp
# update repo index file (generate a new and merge with the current one)
# --url "" mean that we will use relative path
helm repo index ./tmp --merge ./tmp/curr.yaml --url ""
# (basic) copy chart and updated index file to S3
aws s3 cp ./tmp/chart-0.0.0.tgz s3://my-bucket/my-repo/chart-0.0.0.tgz
aws s3 cp ./tmp/index.yaml s3://my-bucket/my-repo/index.yaml
# or
# (cache) copy chart and updated index file to S3 and set cache-control
aws s3 cp ./tmp/chart-0.0.0.tgz s3://my-bucket/my-repo/chart-0.0.0.tgz --cache-control max-age=2592000
aws s3 cp ./tmp/index.yaml s3://my-bucket/my-repo/index.yaml --cache-control max-age=60
#
# if you do not use cache-control, you are probably need to invalidate cloudfront cache
aws cloudfront create-invalidation --distribution-id "FROM TF OUTPUTS" --paths "/my-repo/index.yaml"
```
