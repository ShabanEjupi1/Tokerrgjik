# Flutter-i i sjell vetë rregullat e veta përmes AGP-së. Ky skedar mban vetëm
# atë që i takon këtij aplikacioni — dhe ai nuk përdor refleksion askund, sepse
# nuk ka asnjë varësi që ta kërkonte.
#
# Rreshtat e vetëm që duhen janë ata të motorit të Flutter-it, që AGP i shton
# automatikisht nga `flutter_proguard_rules.pro`.
-dontwarn io.flutter.embedding.**
