import type { Handler } from "aws-lambda";
import { S3Client, ListObjectsCommand, PutObjectCommand } from "@aws-sdk/client-s3"

export const handler: Handler = async (event: any, context: any) => {
  const s3Client = new S3Client({ region: "ap-northeast-1" });
  const listObjectsCommand = new ListObjectsCommand({ Bucket: "img-from" });
  const response = await s3Client.send(listObjectsCommand);
  console.log("Response: ", response);

  const putObjectCommand = new PutObjectCommand({
    Bucket: "img-to",
    Key: "test.txt",
    Body: "hello, this is test file.",
  });
  const response2 = await s3Client.send(putObjectCommand);
  console.log("Response2: ", response2);
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: {event, context, response },
    }),
  };
};
