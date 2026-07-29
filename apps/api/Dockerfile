FROM node:20-alpine AS build
WORKDIR /app

RUN apk add --no-cache openssl

COPY package*.json ./
RUN npm ci

COPY . .
# Prisma 7: prisma.config.ts resolves DATABASE_URL eagerly via env(), even for
# `prisma generate` (which never opens a DB connection, only reads schema).
# Build-time placeholder only — the real DATABASE_URL is injected at
# `docker run` for the runtime stage's `prisma migrate deploy` + the app.
ENV DATABASE_URL="postgresql://placeholder:placeholder@localhost:5432/placeholder?schema=public"
RUN npx prisma generate && npm run build

FROM node:20-alpine
WORKDIR /app

ENV NODE_ENV=production

RUN apk add --no-cache openssl

COPY --from=build /app/dist ./dist
COPY --from=build /app/assets ./assets
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package*.json ./
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/prisma.config.ts ./prisma.config.ts

EXPOSE 3000
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main.js"]
