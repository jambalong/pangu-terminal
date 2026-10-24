require "test_helper"

class InventoryTableTest < ActiveSupport::TestCase
  def rows(text) = InventoryTable.parse(text)[:rows].map { |r| [ r[:ident], r[:quantity] ] }

  test "reads a CSV with the standard header, preferring the key column" do
    text = "key,name,quantity\nshell_credit,Shell Credit,120000\nbasic_energy_core,Basic Energy Core,40\n"

    assert_equal [ [ "shell_credit", "120000" ], [ "basic_energy_core", "40" ] ], rows(text)
  end

  test "header names and order are flexible" do
    assert_equal [ [ "Shell Credit", "5" ] ], rows("Qty,Material\n5,Shell Credit")
    assert_equal [ [ "shell_credit", "5" ] ], rows("owned,name,key\n5,Shell Credit,shell_credit")
  end

  test "a CSV without a header uses the first column and the last column" do
    assert_equal [ [ "Shell Credit", "7" ] ], rows("Shell Credit,7")
    assert_equal [ [ "shell_credit", "7" ] ], rows("shell_credit,Shell Credit,7")
  end

  test "accepts semicolons and tabs as delimiters" do
    assert_equal [ [ "shell_credit", "9" ] ], rows("key;quantity\nshell_credit;9")
    assert_equal [ [ "shell_credit", "9" ] ], rows("key\tquantity\nshell_credit\t9")
  end

  test "handles quotes, doubled quotes, embedded commas and CRLF" do
    text = "name,quantity\r\n\"Gladiator's, Portrait\",\"1,200\"\r\n\"Say \"\"hi\"\"\",3\r\n"

    assert_equal [ [ "Gladiator's, Portrait", "1,200" ], [ "Say \"hi\"", "3" ] ], rows(text)
  end

  test "ignores a byte order mark and blank lines" do
    assert_equal [ [ "a", "1" ], [ "b", "2" ] ], rows("﻿key,quantity\n\na,1\n\n\nb,2\n")
  end

  test "reports the line each row started on, even after quoted newlines" do
    result = InventoryTable.parse("key,quantity\na,1\n\"multi\nline\",2\nb,3\n")

    assert_equal [ "line 2", "line 3", "line 5" ], result[:rows].map { |r| r[:where] }
  end

  test "reads the flat JSON map the API returns" do
    result = InventoryTable.parse('{"shell_credit": 10, "basic_energy_core": "5"}')

    assert_equal [ [ "shell_credit", 10 ], [ "basic_energy_core", "5" ] ], result[:rows].map { |r| [ r[:ident], r[:quantity] ] }
  end

  test "reads a list of entries and unwraps an inventory object" do
    list = InventoryTable.parse('[{"key": "a", "quantity": 1}, {"name": "B B", "qty": 2}, 7]')
    wrapped = InventoryTable.parse('{"inventory": {"a": 1}}')

    assert_equal [ [ "a", 1 ], [ "B B", 2 ], [ nil, nil ] ], list[:rows].map { |r| [ r[:ident], r[:quantity] ] }
    assert_equal [ [ "a", 1 ] ], wrapped[:rows].map { |r| [ r[:ident], r[:quantity] ] }
  end

  test "bad JSON, empty input and invalid encodings return an error and no rows" do
    assert_match(/JSON could not be read/, InventoryTable.parse('{"a": ')[:error])
    assert_match(/empty/, InventoryTable.parse("   \n ")[:error])
    assert_match(/UTF-8/, InventoryTable.parse("key,quantity\n\xFF\xFE,1".b)[:error])
  end

  test "to_csv writes the header and quotes fields that need it" do
    csv = InventoryTable.to_csv([ { key: "a_b", name: "Gladiator's, Portrait", quantity: 3 }, { key: "c", name: 'Say "hi"', quantity: 0 } ])

    assert_equal "key,name,quantity\r\na_b,\"Gladiator's, Portrait\",3\r\nc,\"Say \"\"hi\"\"\",0\r\n", csv
  end

  test "what to_csv writes parses back to the same values" do
    entries = [ { key: "a", name: "A, \"quoted\"\nname", quantity: 12 }, { key: "b", name: "Plain", quantity: 0 } ]

    parsed = InventoryTable.parse(InventoryTable.to_csv(entries))[:rows]

    assert_equal [ [ "a", "12" ], [ "b", "0" ] ], parsed.map { |r| [ r[:ident], r[:quantity] ] }
  end
end
