require 'test_helper'

class BadenWuerttembergPDFExtractorTest < ActiveSupport::TestCase
  def paper(type, contents)
    paper_with_title(type, contents, 'some title')
  end

  def paper_with_title(type, contents, title)
    Struct.new(:doctype, :contents, :title).new(type, contents, title)
  end

  test 'minor interpellation, one person' do
    c = "\n\nKleine Anfrage\n\ndes Abg. Dr. Hans-Ulrich Rülke FDP/DVP\n\n" +
        "und\n\nAntwort\n\ndes Ministeriums für Ländlichen Raum\n\nund Verbraucherschutz\n\n"
    paper = paper(Paper::DOCTYPE_MINOR_INTERPELLATION, c)

    originators = BadenWuerttembergPDFExtractor.new(paper).extract_originators

    assert_equal 1, originators[:people].size
    assert_equal 'Dr. Hans-Ulrich Rülke', originators[:people].first
    assert_equal 'FDP/DVP', originators[:parties].first
  end

  test 'minor interpellation, three people, one with a 3 letter surname' do
    c = "\n\nKleine Anfrage\n\nder Abg. Helmut Rau, Volker Schebesta und Willi Stächele CDU\n" +
        "und\nAntwort\n"
    paper = paper(Paper::DOCTYPE_MINOR_INTERPELLATION, c)

    originators = BadenWuerttembergPDFExtractor.new(paper).extract_originators

    assert_equal 3, originators[:people].size
    assert_equal 'Helmut Rau', originators[:people].first
    assert_equal 'Volker Schebesta', originators[:people].second
    assert_equal 'Willi Stächele', originators[:people].third
    assert_equal 1, originators[:parties].size
    assert_equal 'CDU', originators[:parties].first
  end

  test 'minor interpellation, three people, two parties' do
    c = "\n\nKleine Anfrage\n\nder Abg. Alexander Salomon und Dr. Gisela Splett GRÜNE\n" +
        "und des Abg. Johannes Stober SPD\n\n" +
        "und\n\nAntwort"
    paper = paper(Paper::DOCTYPE_MINOR_INTERPELLATION, c)

    originators = BadenWuerttembergPDFExtractor.new(paper).extract_originators

    assert_equal 3, originators[:people].size
    assert_equal 'Alexander Salomon', originators[:people].first
    assert_equal 'Dr. Gisela Splett', originators[:people].second
    assert_equal 'Johannes Stober', originators[:people].third
    assert_equal 2, originators[:parties].size
    assert_equal 'GRÜNE', originators[:parties].first
    assert_equal 'SPD', originators[:parties].second
  end

  test 'major interpellation, one party' do
    c = "\n\nGroße Anfrage \n\nder Fraktion der FDP/DVP\n\n"
    paper = paper(Paper::DOCTYPE_MAJOR_INTERPELLATION, c)

    originators = BadenWuerttembergPDFExtractor.new(paper).extract_originators

    assert_not_nil originators, 'originators should not be nil'
    assert_equal 1, originators[:parties].size
    assert_equal 'FDP/DVP', originators[:parties].first
  end

  test 'get answerers from paper' do
    c = "Kleine Anfrage\n\ndes Abg. Helmut Walter Rüeck CDU\n\nund\n\nAntwort\n\ndes Ministeriums für Kultus, Jugend und Sport\n\nUmsetzung der Inklusion im Landkreis Schwäbisch Hall"
    paper = paper(Paper::DOCTYPE_MINOR_INTERPELLATION, c)

    answerers = BadenWuerttembergPDFExtractor.new(paper).extract_answerers

    assert_not_nil answerers, 'answerers should not be nil'
    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium für Kultus, Jugend und Sport', answerers[:ministries].first
  end

  test 'get Staaatsministerium' do
    c = "des Abg. Dr. Bernhard Lasotta CDU\n\nund\n\nAntwort\n\ndes Staatsministeriums\n\nBefreiung von Hospizen von der Rundfunkgebührenpflicht"
    paper = paper(Paper::DOCTYPE_MINOR_INTERPELLATION, c)

    answerers = BadenWuerttembergPDFExtractor.new(paper).extract_answerers

    assert_not_nil answerers
    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium', answerers[:ministries].first
  end

  test 'get related ministries' do
    c = "und\n\nAntwort des Staatsministeriums\n\nBefrMit Schreiben vom 6. September 2012 Nr. III/ beantwortet das Staatsministerium\nim Einvernehmen mit dem Ministerium für Arbeit und Sozialordnung, Familie,\nFrauen und Senioren die Kleine Anfrage wie folgt:"
    paper = paper(Paper::DOCTYPE_MINOR_INTERPELLATION, c)

    answerers = BadenWuerttembergPDFExtractor.new(paper).extract_answerers

    assert_not_nil answerers
    assert_equal 2, answerers[:ministries].size
    assert_equal 'Staatsministerium', answerers[:ministries].first
    assert_equal 'Ministerium für Arbeit und Sozialordnung, Familie, Frauen und Senioren', answerers[:ministries].second
  end

  test 'get related ministry with suffix' do
        c = "und\n\nAntwort des Staatsministeriums\n\n" +
        "Mit Schreiben vom 16. Februar 2016 Nr. 6-6002/514 beantwortet das Ministerium \n" +
        "für Finanzen und Wirtschaft im Einvernehmen mit dem Ministerium für Wissenschaft \n" +
        ", Forschung und Kunst für die Landesregierung die Kleine Anfrage wie\nfolgt:"
    paper = paper(Paper::DOCTYPE_MINOR_INTERPELLATION, c)

    answerers = BadenWuerttembergPDFExtractor.new(paper).extract_answerers

    assert_not_nil answerers
    assert_equal 2, answerers[:ministries].size
    assert_equal 'Staatsministerium', answerers[:ministries].first
    assert_equal 'Ministerium für Wissenschaft , Forschung und Kunst', answerers[:ministries].second
  end

  test 'get multiple related ministries' do
    c = "und\n\nAntwort\n\ndes Staatsministeriums\n\nProjekt Übermorgenmacherinnen und Übermorgenmacher\n\nMit Schreiben vom 6. September 2012 Nr. III/ beantwortet das Staatsministerium\nim Einvernehmen mit dem \n\nMinisterium für Arbeit und Sozialordnung, Familie,\n\nFrauen und Senioren, dem Ministerium für Finanzen und Wirtschaft und dem Ministerium\n\nfür Wissenschaft, Forschung und Kunst die Kleine Anfrage wie"
    paper = paper_with_title(Paper::DOCTYPE_MINOR_INTERPELLATION, c, 'Projekt Übermorgenmacherinnen und Übermorgenmacher')

    answerers = BadenWuerttembergPDFExtractor.new(paper).extract_answerers

    assert_not_nil answerers
    assert_equal 4, answerers[:ministries].size
    assert_equal 'Staatsministerium', answerers[:ministries].first
    assert_equal 'Ministerium für Arbeit und Sozialordnung, Familie, Frauen und Senioren', answerers[:ministries].second
    assert_equal 'Ministerium für Finanzen und Wirtschaft', answerers[:ministries].third
    assert_equal 'Ministerium für Wissenschaft, Forschung und Kunst', answerers[:ministries].fourth
  end

  test 'get major ministry' do
    c = "en?\n\nGroße Anfrage\n\nder Fraktion der FDP/DVP\n\nund\n\n" +
        "Antwort\n\nder Landesregierung\n\nInnovation im Wechselspiel von Wissenschaft und Wirtschaft\n\nDru"
    paper = paper_with_title(Paper::DOCTYPE_MINOR_INTERPELLATION, c, 'Innovation im Wechselspiel von Wissenschaft und Wirtschaft')

    answerers = BadenWuerttembergPDFExtractor.new(paper).extract_answerers

    assert_not_nil answerers
    assert_equal 1, answerers[:ministries].size
    assert_equal 'Landesregierung', answerers[:ministries].first
  end

  test 'get related ministry if suffix is near' do
    c = "und\n\nAntwort\n\ndes Ministeriums für Integration\n\n" +
        "Kostenerstattung für Kommunen bei Aufwendungen \n\nim Zusammenhang mit der Flüchtlingsaufnahme\n\n" +
        "[...]\n" +
        "Mit Schreiben vom 8. Dezember 2015 Nr. 2-0141.5/15/7712 beantwortet das\n" +
        " Ministerium für Integration im Einvernehmen mit dem Ministerium für Finanzen\n" +
        "und Wirtschaft die Kleine Anfrage wie folgt:\n" +
        "[...]\nn" +
        "Zu 2.:\n\nIst die Anmietung"
    paper = paper_with_title(
      Paper::DOCTYPE_MINOR_INTERPELLATION,
      c,
      'Kostenerstattung für Kommunen bei Aufwendungen im Zusammenhang mit der Flüchtlingsaufnahme'
    )

    answerers = BadenWuerttembergPDFExtractor.new(paper).extract_answerers

    assert_not_nil answerers
    assert_equal 2, answerers[:ministries].size
    assert_equal 'Ministerium für Integration', answerers[:ministries].first
    assert_equal 'Ministerium für Finanzen und Wirtschaft', answerers[:ministries].second
  end
end