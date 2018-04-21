<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:omv="http://schema.adobe.com/omv/1.0/omv.xsd">
  <xsl:output method="text" encoding="UTF-8" />

<!-- mapping from type (a string) to the corresponding proper TypeScript type -->
<xsl:template match="omv:type">
  <xsl:choose>
    <xsl:when test=".='Any'">any</xsl:when>
    <xsl:when test=".='Array'">any[]</xsl:when>
    <xsl:when test=".='Object'">object</xsl:when>
    <xsl:when test=".='ObjectArray'">object[]</xsl:when>
    <xsl:when test=".='Number'">number</xsl:when>
    <xsl:when test=".='uint'">number</xsl:when>
    <xsl:when test=".='int'">number</xsl:when>
    <xsl:when test=".='bool'">boolean</xsl:when>
    <xsl:when test=".='Boolean'">boolean</xsl:when>
    <xsl:when test=".='String'">string</xsl:when>
    <xsl:when test=".='Undefined'">undefined</xsl:when>
    <xsl:otherwise><xsl:value-of select="." /></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- convert datatype to potentially complex TypeScript type -->
<xsl:template match="omv:datatype">
  <!-- there's also array@size, min, max, and (default?) value -->
  <xsl:apply-templates select="omv:type" />
  <xsl:if test="omv:array">
    <xsl:text>[]</xsl:text>
  </xsl:if>
  <xsl:if test="position() != last()">
    <xsl:text>|</xsl:text>
  </xsl:if>
</xsl:template>

<!-- add "Value" suffix to invalid identifiers -->
<xsl:template match="@name">
  <xsl:value-of select="." />
  <xsl:if test=".='return' or .='default' or .='with'">
    <xsl:text>Value</xsl:text>
  </xsl:if>
</xsl:template>

<!-- convert description / shortdesc contents to something resembling markdown -->
<xsl:template match="omv:br[not(string())]">
  <!-- br sometimes means linebreak (when it's empty),
    but sometimes it means bold (or some sort of code snippet) -->
  <xsl:text>&#10;</xsl:text>
</xsl:template>
<xsl:template match="omv:a|omv:b|omv:br|omv:font|omv:i">
  <!-- each of these seem to represent code fragments -->
  <!-- a elements also have an @href attribute -->
  <xsl:text>`</xsl:text>
  <xsl:value-of select="normalize-space()" />
  <xsl:text>`</xsl:text>
</xsl:template>
<xsl:template match="omv:u">
  <!-- list items, sort of? -->
  <xsl:for-each select="omv:li">
    <xsl:text>- </xsl:text><xsl:apply-templates select="." />
  </xsl:for-each>
</xsl:template>
<xsl:template match="omv:description|omv:shortdesc|omv:li">
  <!-- description = element description { (text | a | b | br | font | i | li | element u { li+ })+ } -->
  <!-- shortdesc = element shortdesc { (text | a | b | i)+ } -->
  <!-- li = element li { (text | a | b | br | i)+ } -->
  <xsl:param name="body">
    <xsl:apply-templates select="text()|node()" />
  </xsl:param>
  <xsl:value-of select="normalize-space($body)" />
</xsl:template>

<xsl:template match="omv:property|omv:classdef|omv:method" mode="comment">
  <xsl:param name="indentation" />
  <!-- no-op if there is nothing to put inside the comment -->
  <xsl:if test="omv:shortdesc|omv:description|omv:parameters">
    <xsl:value-of select="$indentation" />
    <xsl:text>/** </xsl:text><xsl:apply-templates select="omv:shortdesc" />
    <!-- add longer description, if supplied -->
    <xsl:if test="omv:description">
      <xsl:text>&#10;</xsl:text>
      <xsl:value-of select="$indentation" />
      <xsl:text> *&#10;</xsl:text>
      <xsl:value-of select="$indentation" />
      <xsl:text> * </xsl:text><xsl:apply-templates select="omv:description" />
    </xsl:if>
    <!-- add params, for method elements -->
    <xsl:if test="omv:parameters">
      <xsl:text>&#10;</xsl:text>
      <xsl:value-of select="$indentation" />
      <xsl:text> *</xsl:text>
    </xsl:if>
    <xsl:for-each select="omv:parameters/omv:parameter">
      <xsl:text>&#10;</xsl:text>
      <xsl:value-of select="$indentation" />
      <xsl:text> * @param </xsl:text>
      <xsl:apply-templates select="@name" />
      <xsl:if test="omv:shortdesc|omv:description">
        <xsl:text> - </xsl:text>
        <xsl:apply-templates select="omv:shortdesc" />
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="omv:description" />
      </xsl:if>
    </xsl:for-each>
    <!-- add line break and indentation if anything more than the shortdesc was added -->
    <xsl:if test="omv:description|omv:parameters">
      <xsl:text>&#10;</xsl:text>
      <xsl:value-of select="$indentation" />
    </xsl:if>
    <xsl:text> */&#10;</xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="omv:property">
  <xsl:param name="indentation">
    <xsl:text>&#9;</xsl:text>
  </xsl:param>
  <!-- modifier depends on the parent element -->
  <xsl:param name="modifier" />

  <xsl:apply-templates select="." mode="comment">
    <xsl:with-param name="indentation" select="$indentation" />
  </xsl:apply-templates>
  <xsl:value-of select="$indentation" />
  <xsl:value-of select="$modifier" />
  <xsl:value-of select="@name" />
  <xsl:text>: </xsl:text>
  <xsl:apply-templates select="omv:datatype" />
  <xsl:text>;</xsl:text>
  <xsl:if test="omv:datatype/omv:value">
    <xsl:text> // default: </xsl:text>
    <xsl:value-of select="omv:datatype/omv:value" />
  </xsl:if>
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template match="omv:parameter">
  <xsl:apply-templates select="@name" />
  <xsl:if test="@optional">
    <xsl:text>?</xsl:text>
  </xsl:if>
  <xsl:text>: </xsl:text>
  <xsl:apply-templates select="omv:datatype" />
  <xsl:if test="position() != last()">
    <xsl:text>, </xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="omv:method">
  <xsl:param name="indentation">
    <xsl:text>&#9;</xsl:text>
  </xsl:param>
  <!-- parameterizing "name" lets us override this for constructors without too much extra code -->
  <xsl:param name="name">
    <xsl:value-of select="@name" />
  </xsl:param>
  <!-- modifier depends on the parent element -->
  <xsl:param name="modifier" />

  <xsl:apply-templates select="." mode="comment">
    <xsl:with-param name="indentation" select="$indentation" />
  </xsl:apply-templates>
  <xsl:value-of select="$indentation" />
  <xsl:value-of select="$modifier" />
  <xsl:value-of select="$name" />
  <xsl:text>(</xsl:text>
  <xsl:apply-templates select="omv:parameters/omv:parameter" />
  <xsl:text>);</xsl:text>
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- elements elements can have @type: "class" | "instance" | "constructor" | "event" -->
<xsl:template match="omv:elements[@type='class']">
  <xsl:apply-templates select="omv:property|omv:method">
    <xsl:with-param name="modifier"><xsl:text>static </xsl:text></xsl:with-param>
  </xsl:apply-templates>
</xsl:template>
<xsl:template match="omv:elements[@type='constructor']">
  <xsl:apply-templates select="omv:method">
    <xsl:with-param name="name"><xsl:text>new </xsl:text></xsl:with-param>
  </xsl:apply-templates>
</xsl:template>
<xsl:template match="omv:elements[@type='event']">
  <xsl:param name="indentation">
    <xsl:text>&#9;</xsl:text>
  </xsl:param>

  <xsl:for-each select="omv:method">
    <xsl:apply-templates select="." mode="comment">
      <xsl:with-param name="indentation" select="$indentation" />
    </xsl:apply-templates>
    <xsl:value-of select="$indentation" />
    <xsl:value-of select="@name" />
    <xsl:text>: Function;</xsl:text>
    <xsl:text>&#10;</xsl:text>
  </xsl:for-each>
</xsl:template>
<xsl:template match="omv:elements[@type='instance']">
  <xsl:apply-templates select="omv:property|omv:method" />
</xsl:template>

<xsl:template match="omv:classdef">
  <xsl:text>&#10;</xsl:text>
  <xsl:apply-templates select="." mode="comment" />
  <xsl:text>export declare class </xsl:text><xsl:value-of select="@name" />
  <xsl:if test="omv:superclass">
    <xsl:text> extends </xsl:text>
    <xsl:value-of select="omv:superclass" />
  </xsl:if>
  <xsl:text> {&#10;</xsl:text>
  <xsl:apply-templates select="omv:elements" />
  <xsl:text>}&#10;</xsl:text>
</xsl:template>

<xsl:template match="/">
  <xsl:apply-templates select="omv:dictionary/omv:package/omv:classdef" />
</xsl:template>

</xsl:stylesheet>
