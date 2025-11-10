FROM swift:6.0 AS build
WORKDIR /app
COPY Package.swift ./
COPY Sources ./Sources
COPY Content ./Content
RUN swift build -c release --static-swift-stdlib

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /run
COPY --from=build /app/.build/release/BlogServer ./BlogServer
COPY --from=build /app/Content ./Content
EXPOSE 8080
CMD ["./BlogServer"]
