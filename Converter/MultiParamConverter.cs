using System.Globalization;

namespace WonderWall.Converter;

public class MultiParamConverter : IMultiValueConverter
{
    public object? Convert(object[]? values, Type targetType, object parameter, CultureInfo culture)
    {
        return values; 
    }

    public object[]? ConvertBack(object? value, Type[] targetTypes, object parameter, CultureInfo culture)
    {
        return value as object[];
    }
}
