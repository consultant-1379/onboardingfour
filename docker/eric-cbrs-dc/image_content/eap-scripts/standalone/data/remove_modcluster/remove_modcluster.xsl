<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" indent="yes" encoding="utf-8"/>
  <xsl:strip-space elements="*" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//*[@module='org.jboss.as.modcluster']" >
  </xsl:template>
  <xsl:template match="//*[local-name()='subsystem' and contains(namespace-uri(),'urn:jboss:domain:modcluster')]"/>
</xsl:stylesheet>

