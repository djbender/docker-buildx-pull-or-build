FROM busybox

ARG FOO=Hello
ENV FOO $FOO

ARG BAR=World
ENV BAR $BAR

ARG BAZ
ENV BAZ $BAZ

RUN echo $FOO $BAR $BAZ
CMD echo $FOO $BAR $BAZ
