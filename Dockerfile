# Dy fazash, sepse imazhi i Dart-it është ~1.3 GB dhe imazhi që del këtu është
# ~15 MB. Në një disk që rri mbi 80% të mbushur, kjo nuk është hollësi.
FROM dart:stable AS build

WORKDIR /src

# Motori kopjohet i pari dhe veçmas: ai ndryshon shumë më rrallë se serveri, dhe
# kështu `pub get` nuk ripërsëritet sa herë preket një rresht i serverit.
COPY engine/pubspec.yaml ./engine/
COPY server/pubspec.yaml ./server/
COPY engine/ ./engine/
RUN cd server && dart pub get

COPY server/ ./server/
RUN cd server && dart pub get --offline && \
    dart compile exe bin/server.dart -o /src/tokerrgjik-server

# `scratch` + runtime-i i Dart-it: asnjë shpërndarje, asnjë menaxher paketash,
# asnjë guaskë. Nuk ka çfarë të përditësohet dhe as ku të hyhet.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /src/tokerrgjik-server /app/tokerrgjik-server
COPY --from=build /src/server/public/ /app/public/

WORKDIR /app
ENV TOKERRGJIK_PUBLIC=/app/public
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/app/tokerrgjik-server"]
