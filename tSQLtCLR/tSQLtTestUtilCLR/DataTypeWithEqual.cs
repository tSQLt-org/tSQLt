using System;
using System.Data.SqlTypes;
using System.IO;
using Microsoft.SqlServer.Server;

namespace tSQLtTestUtilCLR
{
    [SqlUserDefinedType(Format.UserDefined, MaxByteSize = 5, IsFixedLength = true)]
    public class DataTypeWithEqual : INullable, IBinarySerialize, IComparable
    {
        private int _i;

        public bool IsNull { get; private set; }

        public override string ToString()
        {
            return "<<DataTypeWithEqual>>";
        }

        public int CompareTo(object obj)
        {
            if (!(obj is DataTypeWithEqual))
            {
                throw new ArgumentException("Object is not a DataTypeWithEqual.");
            }

            var p2 = (DataTypeWithEqual) obj;

            return _i.CompareTo(p2._i);
        }

        public static DataTypeWithEqual Parse(SqlString s)
        {
            return new DataTypeWithEqual() { IsNull = (s.IsNull), _i = int.Parse(s.Value) };
        }

        public static DataTypeWithEqual Null
        {
            get { return new DataTypeWithEqual() { IsNull = true }; }
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
