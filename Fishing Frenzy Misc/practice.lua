local dropdown = AddDropdown({
    Name = "Color",
    List = {"Red", "Green", "Blue"},
    Multi = true,
    Callback = function(selectedValues)
        print("Selected colors: " .. table.concat(selectedValues, ", "))
    end
})
