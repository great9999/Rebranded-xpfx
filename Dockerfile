# syntax=docker/dockerfile:1
FROM node:20-alpine AS base
ENV NODE_ENV=production
WORKDIR /app

FROM base AS deps
COPY package.json package-lock.json .npmrc ./
COPY artifacts/api-server/package.json ./artifacts/api-server/package.json
COPY artifacts/nextrade/package.json ./artifacts/nextrade/package.json
COPY artifacts/admin-portal/package.json ./artifacts/admin-portal/package.json
COPY lib/api-client-react/package.json ./lib/api-client-react/package.json
COPY lib/api-zod/package.json ./lib/api-zod/package.json
COPY lib/db/package.json ./lib/db/package.json
COPY artifacts/db/package.json ./artifacts/db/package.json
RUN npm ci --no-audit --no-fund

FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN node scripts/predeploy.mjs --skip-env-check \
    && npm run build --workspace artifacts/api-server \
    && npm run build --workspace artifacts/nextrade \
    && npm run build --workspace artifacts/admin-portal

FROM base AS runtime
ENV NODE_ENV=production
ENV PORT=3000
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/artifacts ./artifacts
COPY --from=build /app/lib ./lib
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/package-lock.json ./package-lock.json
COPY --from=build /app/.npmrc ./.npmrc
EXPOSE 3000
CMD ["node", "--enable-source-maps", "artifacts/api-server/dist/artifacts/api-server/src/index.js"]
