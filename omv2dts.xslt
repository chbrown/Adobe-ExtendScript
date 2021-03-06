<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:omv="http://schema.adobe.com/omv/1.0/omv.xsd">
  <xsl:output method="text" encoding="UTF-8" />

<xsl:template name="interface">
  <xsl:param name="identifier" />
  <xsl:param name="extends" />
  <xsl:param name="elements" />

  <xsl:text>interface </xsl:text>
  <xsl:value-of select="$identifier" />
  <xsl:if test="$identifier = 'Array'">
    <!-- hack for TypeScript's "Global type 'Array' must have 1 type parameter(s)." constraint -->
    <xsl:text>&lt;T = any&gt;</xsl:text>
  </xsl:if>
  <xsl:if test="$extends">
    <xsl:text> extends </xsl:text>
    <xsl:for-each select="$extends">
      <xsl:apply-templates select="." />
      <xsl:if test="position() != last()">
        <xsl:text>, </xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:if>
  <xsl:text> {&#10;</xsl:text>
  <xsl:apply-templates select="$elements" />
  <xsl:text>}&#10;</xsl:text>
</xsl:template>

<xsl:template name="const">
  <xsl:param name="identifier" />
  <xsl:param name="type" />

  <xsl:text>declare const </xsl:text>
  <xsl:value-of select="$identifier" />
  <xsl:text>: </xsl:text>
  <xsl:value-of select="$type" />
  <xsl:text>;&#10;</xsl:text>
</xsl:template>

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
    <xsl:when test=".='Rect'">Rectangle</xsl:when><!-- fix typo -->
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
  <xsl:variable name="body">
    <xsl:apply-templates select="text()|node()" />
  </xsl:variable>
  <xsl:value-of select="normalize-space($body)" />
</xsl:template>

<xsl:template match="omv:property|omv:classdef|omv:method" mode="comment">
  <xsl:param name="indentation" />
  <!-- no-op if there is nothing to put inside the comment -->
  <xsl:if test="omv:shortdesc|omv:description|omv:parameters/omv:parameter[omv:shortdesc|omv:description]">
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

  <xsl:apply-templates select="." mode="comment">
    <xsl:with-param name="indentation" select="$indentation" />
  </xsl:apply-templates>
  <xsl:value-of select="$indentation" />
  <xsl:if test="@rwaccess='readonly'">
    <xsl:text>readonly </xsl:text>
  </xsl:if>
  <xsl:value-of select="@name" />
  <xsl:if test="omv:datatype">
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="omv:datatype" />
  </xsl:if>
  <xsl:text>;</xsl:text>
  <xsl:if test="omv:datatype/omv:value">
    <xsl:text> // default: </xsl:text>
    <xsl:value-of select="omv:datatype/omv:value" />
  </xsl:if>
  <xsl:text>&#10;</xsl:text>
</xsl:template>
<!-- special global handling -->
<xsl:template match="omv:classdef[@name='global']//omv:property">
  <xsl:text>&#10;</xsl:text>
  <xsl:apply-templates select="." mode="comment" />
  <xsl:text>declare const </xsl:text>
  <xsl:value-of select="@name" />
  <xsl:text>: </xsl:text>
  <xsl:apply-templates select="omv:datatype" />
  <xsl:text>;</xsl:text>
  <xsl:text>&#10;</xsl:text>
</xsl:template>
<!-- special special-global-handling -->
<xsl:template match="omv:classdef[@name='global']//omv:property[@name='undefined']">
  <!-- suppress declaration (emit nothing) -->
</xsl:template>

<xsl:template match="omv:parameter">
  <xsl:apply-templates select="@name" />
  <xsl:if test="@optional or omv:datatype/omv:value">
    <xsl:text>?</xsl:text>
  </xsl:if>
  <xsl:if test="omv:datatype">
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="omv:datatype" />
  </xsl:if>
  <xsl:if test="position() != last()">
    <xsl:text>, </xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="omv:method">
  <xsl:param name="indentation">
    <xsl:text>&#9;</xsl:text>
  </xsl:param>

  <xsl:apply-templates select="." mode="comment">
    <xsl:with-param name="indentation" select="$indentation" />
  </xsl:apply-templates>
  <xsl:value-of select="$indentation" />
  <xsl:choose>
    <xsl:when test="@name='[]'">
      <xsl:text>[</xsl:text>
      <xsl:apply-templates select="omv:parameters/omv:parameter" />
      <xsl:text>]</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="@name" />
      <xsl:text>(</xsl:text>
      <xsl:apply-templates select="omv:parameters/omv:parameter" />
      <xsl:text>)</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:if test="omv:datatype">
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="omv:datatype" />
  </xsl:if>
  <xsl:text>;</xsl:text>
  <xsl:text>&#10;</xsl:text>
</xsl:template>
<!-- constructors are simpler -->
<xsl:template match="omv:elements[@type='constructor']/omv:method">
  <xsl:param name="indentation">
    <xsl:text>&#9;</xsl:text>
  </xsl:param>

  <xsl:apply-templates select="." mode="comment">
    <xsl:with-param name="indentation" select="$indentation" />
  </xsl:apply-templates>
  <xsl:value-of select="$indentation" />
  <xsl:text>new (</xsl:text>
  <xsl:apply-templates select="omv:parameters/omv:parameter" />
  <xsl:text>)</xsl:text>
  <xsl:text>: </xsl:text>
  <xsl:value-of select="@name" />
  <xsl:text>;</xsl:text>
  <xsl:text>&#10;</xsl:text>
</xsl:template>
<!-- event methods are even simpler -->
<xsl:template match="omv:elements[@type='event']/omv:method">
  <xsl:param name="indentation">
    <xsl:text>&#9;</xsl:text>
  </xsl:param>

  <xsl:apply-templates select="." mode="comment">
    <xsl:with-param name="indentation" select="$indentation" />
  </xsl:apply-templates>
  <xsl:value-of select="$indentation" />
  <xsl:value-of select="@name" />
  <xsl:text>: Function;</xsl:text>
  <xsl:text>&#10;</xsl:text>
</xsl:template>
<!-- special global handling -->
<xsl:template match="omv:classdef[@name='global']//omv:method">
  <xsl:text>&#10;</xsl:text>
  <xsl:apply-templates select="." mode="comment" />
  <xsl:text>declare function </xsl:text>
  <xsl:value-of select="@name" />
  <xsl:text>(</xsl:text>
  <xsl:apply-templates select="omv:parameters/omv:parameter" />
  <xsl:text>)</xsl:text>
  <xsl:if test="omv:datatype">
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="omv:datatype" />
  </xsl:if>
  <xsl:text>;</xsl:text>
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- elements elements can have @type: "class" | "instance" | "constructor" | "event" -->
<xsl:template match="omv:elements">
  <xsl:apply-templates select="omv:property|omv:method" />
</xsl:template>

<xsl:template match="omv:classdef">
  <xsl:variable name="instance-elements" select="omv:elements[@type='instance']|omv:elements[@type='event']" />
  <xsl:variable name="class-elements" select="omv:elements[@type='constructor']|omv:elements[@type='class']" />
  <xsl:variable name="ctor-identifier">
    <xsl:value-of select="@name" />
    <!-- if there are any instance/event fields,
      constructor/class fields get relegated to a separate suffixed interface -->
    <xsl:if test="$instance-elements">
      <xsl:text>Constructor</xsl:text>
    </xsl:if>
  </xsl:variable>

  <xsl:text>&#10;</xsl:text>
  <xsl:if test="$instance-elements or not($class-elements)">
    <!-- the instance/event fields are always put in the main interface -->
    <xsl:call-template name="interface">
      <xsl:with-param name="identifier" select="@name" />
      <xsl:with-param name="extends" select="omv:superclass" />
      <xsl:with-param name="elements" select="$instance-elements" />
    </xsl:call-template>
  </xsl:if>
  <xsl:if test="$class-elements">
    <!-- the constructor/class fields go into a different interface -->
    <xsl:call-template name="interface">
      <xsl:with-param name="identifier" select="$ctor-identifier" />
      <!-- ignore any superclass -->
      <xsl:with-param name="elements" select="$class-elements" />
    </xsl:call-template>
    <!-- global -->
    <xsl:apply-templates select="." mode="comment" />
    <xsl:call-template name="const">
      <xsl:with-param name="identifier" select="@name" />
      <xsl:with-param name="type" select="$ctor-identifier" />
    </xsl:call-template>
  </xsl:if>
</xsl:template>
<!-- special handling for "global" classdef -->
<xsl:template match="omv:classdef[@name='global']">
  <xsl:apply-templates select="omv:elements" />
</xsl:template>

<xsl:template match="/">
  <xsl:apply-templates select="omv:dictionary/omv:package/omv:classdef" />
</xsl:template>

</xsl:stylesheet>
