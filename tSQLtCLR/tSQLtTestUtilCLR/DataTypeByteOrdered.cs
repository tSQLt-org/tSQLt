using System;
using System.Data.SqlTypes;
using System.IO;
using Microsoft.SqlServer.Server;

namespace tSQLtTestUtilCLR
{
    [SqlUserDefinedType(Format.UserDefined, MaxByteSize = 5, IsFixedLength = true, IsByteOrdered = true)]
    public class DataTypeByteOrdered : INullable, IBinarySerialize, IComparable
    {
        private int _i;

        public bool IsNull { get; private set; }

        public override string ToString()
        {
            return "<<DataTypeByteOrdered>>";
        }

        public int CompareTo(object obj)
        {
            if (!(obj is DataTypeByteOrdered))
            {
                throw new ArgumentException("Object is not a DataTypeByteOrdered.");
            }

            var p2 = (DataTypeByteOrdered)obj;

            return _i.CompareTo(p2._i);
        }

        public static DataTypeByteOrdered Parse(SqlString s)
        {
            return new DataTypeByteOrdered() { IsNull = (s.IsNull), _i = int.Parse(s.Value) };
        }

        public static DataTypeByteOrdered Null
        {
            get { return new DataTypeByteOrdered() { IsNull = true }; }
        }

        public void Read(BinaryReader r)
        {
            IsNull = r.ReadBoolean();
            _i = r.ReadInt32();
        }

        public void Write(BinaryWriter w)
        {
            w.Write(IsNull);
            w.Write(_i);
        }
    }
}
