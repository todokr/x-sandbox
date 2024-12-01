import { Buffer } from "node:buffer";
import type { APIGatewayEvent, Context, Handler } from "aws-lambda";
import { S3Client, GetObjectCommand, S3ServiceException, NoSuchKey, PutObjectCommand } from "@aws-sdk/client-s3"
import sharp from "sharp";

export const handler: Handler = async (event: unknown, context: Context) => {
  console.log({event});

  const req = parseRequest(event);

  if (!req.valid) {
    console.log("Bad Request", event);
    return {
      statusCode: 400,
      body: "Bad Request",
    };
  }

  const s3Client = new S3Client({ region: "ap-northeast-1" });

  let bytes: Uint8Array | undefined = undefined;
  try {
    const response = await s3Client.send(new GetObjectCommand({
      Bucket: "img-from",
      Key: `${req.args.from.key}`,
    }));
    bytes = await response.Body?.transformToByteArray();
  } catch (e) {
    if (e instanceof NoSuchKey) {
      const msg = `Speficied key not found: ${req.args.from.key}`
      console.error(msg);
      return {
        statusCode: 200,
        body: { msg },
      };
    } else if (e instanceof S3ServiceException) {
      const msg = `S3ServiceException: ${e.message}`
      console.error(msg);
      return {
        statusCode: 200,
        body: { msg },
      };
    } else {
      const msg = `Unknown error: ${e}`
      console.error(msg);
      return {
        statusCode: 500,
        body: { msg },
      };
    }
  }

  if (!bytes === undefined) {
    const msg = `Specified content is empty: ${req.args.from.key}`
    console.error(msg);
    return {
      statusCode: 200,
      body: { msg },
    };
  }

  let resized: Uint8Array;
  try {
    resized = await sharp(bytes)
      .resize(req.args.size.width, req.args.size.height)
      .toBuffer();
  } catch (e) {
    const msg = `Failed to resize: ${e}`
    console.error(msg, req.args.from.key, req.args.size);
    return {
      statusCode: 500,
      body: { msg },
    };
  }

  try {
    await s3Client.send(new PutObjectCommand({
      Bucket: "img-to",
      Key: `${req.args.to.key}`,
      Body: resized,
    }));
  } catch (e) {
    const msg = `Failed to upload: ${e}`
    console.error(msg, req.args.to.key);
    return {
      statusCode: 500,
      body: { msg },
    };
  }

  return {
    statusCode: 200,
    body: { msg: "Success"},
  };
};

export const parseRequest = (body: unknown): Request | {valid: false} => {
  if (!isArgs(body)) {
    return { valid: false };
  } else {
    return {valid: true, args: body}
  }
}

const isObject = (obj: unknown): obj is Record<string, unknown> => {
  return typeof obj === "object" && obj !== null;
}

type Request = {
  valid: true;
  args: Arguments;
}

type Arguments = {
  from: S3Path;
  to: S3Path;
  size: Size;
}
const isArgs = (x: unknown): x is Arguments => {
  if (!isObject(x)) return false;

  const hasFromTo = "from" in x && isS3Path(x.from) && "to" in x && isS3Path(x.to);
  if (!hasFromTo) return false;

  const hasSize = "size" in x && isSize(x.size);
  if (!hasSize) return false;

  return true;
}

type S3Path = {
  key: string;
}
const isS3Path = (x: unknown): x is S3Path => {
  if (!isObject(x)) return false;

  const hasKey = "key" in x && typeof x.key === "string";
  if (!hasKey) return false;

  return true;
}

type Size = {
  width: number;
  height: number;
}
const isSize = (x: unknown): x is Size => {
  if (!isObject(x)) return false;

  const hasWidth = "width" in x && typeof x.width === "number";
  if (!hasWidth) return false;

  const hasHeight = "height" in x && typeof x.height === "number";
  if (!hasHeight) return false;

  return true;
}
