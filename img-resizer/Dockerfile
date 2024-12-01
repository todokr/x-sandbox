FROM public.ecr.aws/lambda/nodejs:20 as builder
WORKDIR /usr/app
COPY package.json package.json
COPY pnpm-lock.yaml pnpm-lock.yaml
COPY src/index.ts src/index.ts
RUN npm i -g pnpm
RUN pnpm i --frozen-lockfile
RUN pnpm build

FROM public.ecr.aws/lambda/nodejs:20
WORKDIR ${LAMBDA_TASK_ROOT}
RUN npm install --cpu=x64 --os=linux --libc=glibc sharp
COPY --from=builder /usr/app/dist/* ./
CMD ["index.handler"]
