import React from "react";
import cw from "../assets/nt.svg";
import "./style.css";

const Header = () => {
  return (
    <div>
      <div className="text-center">
        <img src={cw} alt="nioyatech" className="nt" />
        <h6 className="text-center mt-5">
          Test App for A3M.
        </h6>
        <h1 className="text-center mt-5 header-text">To Do List</h1>
      </div>
    </div>
  );
};

export default Header;
