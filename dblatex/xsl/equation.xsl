<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <!--
    If equation content isn't wrapped with one of $...$ or \[...\] or \(...\)
    then dblatex automatically wraps it with $...$
    It does this for <equation>, <informalequation>, and <inlineequation>
    despite the fact that $...$ doesn't render in block mode!
    I consider this a defect, and I don't want to have to write \[...\]
    in every STEM block.

    Here we make <informalequation> act more like <equation> by wrapping it in
    an explicit math environment. Alternatively, when the equation has a role,
    that's used to wrap the block with custom commands; for example when
    `role="Role"` then the content is wrapped with `\BeginRole` and `\EndRole`.

    Stock dblatex also runs normalize-space() on the alt content, removing
    newlines and turning % comments into catastrophe.

    LIMITATIONS compared with <equation>
     * We don't handle label.id
     * We don't strip wrapping math-delimiters
  -->

  <xsl:template match="informalequation">
    <xsl:variable name="content">
      <xsl:call-template name="scape-encode">
        <!-- No call to normalize-space() before encoding. -->
        <xsl:with-param name="string" select="alt"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="@role">
        <xsl:text>&#10;\Begin</xsl:text>
        <xsl:value-of select="@role"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:value-of select="$content"/>
        <xsl:text>&#10;\End</xsl:text>
        <xsl:value-of select="@role"/>
        <xsl:text>&#10;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&#10;\begin{displaymath}&#10;</xsl:text>
        <xsl:value-of select="$content"/>
        <xsl:text>&#10;\end{displaymath}&#10;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
