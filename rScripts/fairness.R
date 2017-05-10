# 12 flows, je .2 mbps required und .2 erhalten
flows <- data.frame(bw = rep(.2, 12), req = rep(.2, 12))

# Fall 1: Aufteilung Flowanzahl auf die Links 7 : 5 und gleichmaessige Bandbreitenaufteilung innerhalb der Links. Erhaltene Gesamtbandbreite = 2 mbps.
flows1 <- flows
flows1$bw[1:7] <- .2 * 5 / 7

# Fall 2: Aufteilung Flowanzahl auf die Links 6 : 6 und gleichmaessige Bandbreitenaufteilung innerhalb der Links. Erhaltene Gesamtbandbreite = 2 mbps.
flows2 <- flows
flows2$bw <- .2 * 5 / 6

# Normierte erhaltene Bandbreite.
flows1$x <- (flows1$bw/flows1$req) / sum(flows1$bw/flows1$req)
flows2$x <- (flows2$bw/flows2$req) / sum(flows2$bw/flows2$req)

# Jain's fairness index.
jain <- function(x) {return(sum(x)^2 / (length(x) * sum(x^2)))}

# => .97
jain(flows1$x)
# => 1
jain(flows2$x)

